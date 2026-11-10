import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_http_client.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/config/api_config.dart';
import '../database/db_manager.dart';

class CategoryApi {
  CategoryApi({http.Client? client})
    : _client = client ?? ApiHttpClient.instance;

  static const String categoryLvl1Endpoint = 'categorylvl1';
  static const String categoryLvl2Endpoint = 'categorylvl2';
  static const String categoryLvl3Endpoint = 'categorylvl3';

  final http.Client _client;

  // SYNC ALL CATEGORIES

  Future<CategorySyncResult> syncCategories({
    String? categoryLvl1Url,
    String? categoryLvl2Url,
    String? categoryLvl3Url,
    Map<String, String>? headers,
    bool clearExistingData = false,
  }) async {
    final results = await Future.wait([
      _fetchCategoryRows(
        categoryLvl1Url ?? ApiConfig.url(CategoryApi.categoryLvl1Endpoint),
        headers: headers,
      ),
      _fetchCategoryRows(
        categoryLvl2Url ?? ApiConfig.url(CategoryApi.categoryLvl2Endpoint),
        headers: headers,
      ),
      _fetchCategoryRows(
        categoryLvl3Url ?? ApiConfig.url(CategoryApi.categoryLvl3Endpoint),
        headers: headers,
      ),
    ]);

    final payload = CategoryPayload(
      categoryLvl1: results[0],
      categoryLvl2: results[1],
      categoryLvl3: results[2],
    );

    final result = await saveCategories(
      payload,
      clearExistingData: clearExistingData,
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> _fetchCategoryRows(
    String apiUrl, {
    Map<String, String>? headers,
  }) async {
    if (apiUrl.trim().isEmpty) {
      throw Exception('Category API URL is not configured.');
    }

    final stopwatch = Stopwatch()..start();

    final response = await _client
        .get(Uri.parse(apiUrl), headers: headers)
        .timeout(const Duration(seconds: 60));

    stopwatch.stop();

   
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Category API failed.\n'
        'Status: ${response.statusCode}\n'
        'The server returned an unsuccessful response.',
      );
    }

    if (response.body.trim().isEmpty) {
      debugPrint('EMPTY RESPONSE');

      return const [];
    }

    final decodedJson = jsonDecode(response.body);

    final rows = CategoryPayload.rowsFromJson(decodedJson);

    debugPrint('PARSED ROW COUNT: ${rows.length}');

    return rows;
  }

  
  Future<CategorySyncResult> saveCategories(
    CategoryPayload payload, {
    bool clearExistingData = false,
  }) async {
    final db = await DBManager.getDatabase(AppDatabase.fudo);

    return db.transaction((txn) async {
      if (clearExistingData) {
        await _clearCategoryTables(txn);
      }

      final categoryTypes = await _upsertRows(
        txn,
        tableName: 'Category_Type',
        rows: payload.categoryTypes,
        columns: CategoryPayload.categoryTypeColumns,
        requiredColumns: const ['Cat_Type'],
      );

      final categoryLvl1 = await _upsertRows(
        txn,
        tableName: 'Category_Lvl1',
        rows: payload.categoryLvl1,
        columns: CategoryPayload.categoryLvl1Columns,
        requiredColumns: const ['Cat_Code'],
      );

      final categoryLvl2 = await _upsertRows(
        txn,
        tableName: 'Category_Lvl2',
        rows: payload.categoryLvl2,
        columns: CategoryPayload.categoryLvl2Columns,
        requiredColumns: const ['Cat_Code', 'Cat_Lv2_Code'],
      );

      final categoryLvl3 = await _upsertRows(
        txn,
        tableName: 'Category_Lvl3',
        rows: payload.categoryLvl3,
        columns: CategoryPayload.categoryLvl3Columns,
        requiredColumns: const ['Cat_Code', 'Cat_Lv2_Code', 'Cat_Lv3_Code'],
      );

      return CategorySyncResult(
        categoryTypes: categoryTypes,
        categoryLvl1: categoryLvl1,
        categoryLvl2: categoryLvl2,
        categoryLvl3: categoryLvl3,
      );
    });
  }

 
  Future<void> _clearCategoryTables(Transaction txn) async {
    await txn.delete('Category_Lvl3');
    await txn.delete('Category_Lvl2');
    await txn.delete('Category_Lvl1');
    await txn.delete('Category_Type');
  }

  Future<int> _upsertRows(
    Transaction txn, {
    required String tableName,
    required List<Map<String, dynamic>> rows,
    required Set<String> columns,
    required List<String> requiredColumns,
  }) async {
    var savedCount = 0;

    for (final row in rows) {
      final normalizedRow = _normalizeRow(row, columns);

      final valid = requiredColumns.every((column) {
        final value = normalizedRow[column];

        return value != null && value.toString().trim().isNotEmpty;
      });

      if (!valid) {
        continue;
      }

      await txn.insert(
        tableName,
        normalizedRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      savedCount++;
    }

    return savedCount;
  }


  Map<String, dynamic> _normalizeRow(
    Map<String, dynamic> row,
    Set<String> columns,
  ) {
    final normalizedRow = <String, dynamic>{};

    for (final column in columns) {
      final value = _readValue(row, column);

      if (value != null) {
        normalizedRow[column] = value;
      }
    }

    return normalizedRow;
  }

  dynamic _readValue(Map<String, dynamic> row, String columnName) {
    if (row.containsKey(columnName)) {
      return row[columnName];
    }

    final normalizedColumn = _normalizeKey(columnName);

    for (final entry in row.entries) {
      if (_normalizeKey(entry.key) == normalizedColumn) {
        return entry.value;
      }
    }

    return null;
  }

  String _normalizeKey(String value) {
    return value
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toLowerCase()
        .replaceAll('lvl', 'lv');
  }
}


class CategoryPayload {
  const CategoryPayload({
    this.categoryTypes = const [],
    this.categoryLvl1 = const [],
    this.categoryLvl2 = const [],
    this.categoryLvl3 = const [],
  });

  final List<Map<String, dynamic>> categoryTypes;
  final List<Map<String, dynamic>> categoryLvl1;
  final List<Map<String, dynamic>> categoryLvl2;
  final List<Map<String, dynamic>> categoryLvl3;

  static const categoryTypeColumns = {'Cat_Type', 'Cat_Name', 'Cat_Name2'};

  static const categoryLvl1Columns = {
    'Cat_Code',
    'Cat_Name',
    'Cat_Name2',
    'Cat_Type',
    'Color_Code',
    'Cat_Image',
    'Dine',
    'TakeAway',
    'Delivery',
    'Display_Order_ID',
  };

  static const categoryLvl2Columns = {
    'Cat_Code',
    'Cat_Lv2_Code',
    'Cat_Lv2_Name',
    'Cat_Lv2_Name2',
    'Display_Order_ID',
  };

  static const categoryLvl3Columns = {
    'Cat_Code',
    'Cat_Lv2_Code',
    'Cat_Lv3_Code',
    'Cat_Lv3_Name',
    'Cat_Lv3_Name2',
  };

  // JSON → ROWS

  static List<Map<String, dynamic>> rowsFromJson(dynamic json) {
    final root = _unwrapRoot(json);

    if (root is List) {
      return _asRows(root);
    }

    if (root is Map) {
      final map = Map<String, dynamic>.from(root);

      for (final value in map.values) {
        final rows = _asRows(value);

        if (rows.isNotEmpty) {
          return rows;
        }
      }
    }

    return const [];
  }

  static dynamic _unwrapRoot(dynamic json) {
    var current = json;

    while (current is Map) {
      final map = Map<String, dynamic>.from(current);

      if (map.containsKey('data')) {
        current = map['data'];
      } else if (map.containsKey('result')) {
        current = map['result'];
      } else if (map.containsKey('payload')) {
        current = map['payload'];
      } else {
        return current;
      }
    }

    return current;
  }


  static List<Map<String, dynamic>> _asRows(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }
}

class CategorySyncResult {
  const CategorySyncResult({
    required this.categoryTypes,
    required this.categoryLvl1,
    required this.categoryLvl2,
    required this.categoryLvl3,
  });

  final int categoryTypes;
  final int categoryLvl1;
  final int categoryLvl2;
  final int categoryLvl3;

  int get total => categoryTypes + categoryLvl1 + categoryLvl2 + categoryLvl3;
}
