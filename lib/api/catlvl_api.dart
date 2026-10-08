import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../session/api_config.dart';
import '../database/db_manager.dart';

class CatLvlApi {
  CatLvlApi({http.Client? client}) : _client = client ?? http.Client();

  static const String catLvl1Endpoint = 'catlv1lang';
  static const String catLvl2Endpoint = 'catlv2lang';


  final http.Client _client;

  Future<CatLvlSyncResult> syncCatLevels({
    String? catLvl1Url,
    String? catLvl2Url,
    Map<String, String>? headers,
    bool clearExistingData = false,
  }) async {
    final payload = CatLvlPayload(
      catLvl1: await _fetchRows(
        catLvl1Url ?? ApiConfig.url(CatLvlApi.catLvl1Endpoint),
        headers: headers,
      ),
      catLvl2: await _fetchRows(
        catLvl2Url ?? ApiConfig.url(CatLvlApi.catLvl2Endpoint),
        headers: headers,
      ),
    );

    return saveCatLevels(
      payload,
      clearExistingData: clearExistingData,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRows(
    String apiUrl, {
    Map<String, String>? headers,
  }) async {
    if (apiUrl.trim().isEmpty) return const [];

    final response = await _client.get(Uri.parse(apiUrl), headers: headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Category level API failed with status ${response.statusCode}: $apiUrl',
      );
    }

    return CatLvlPayload.rowsFromJson(jsonDecode(response.body));
  }

  Future<CatLvlSyncResult> saveCatLevels(
    CatLvlPayload payload, {
    bool clearExistingData = false,
  }) async {
    final db = await DBManager.getDatabase(AppDatabase.fudo);

    return db.transaction((txn) async {
      if (clearExistingData) {
        await txn.delete('Category_Lvl3');
        await txn.delete('Category_Lvl2');
        await txn.delete('Category_Lvl1');
      }

      final catLvl1 = await _upsertRows(
        txn,
        tableName: 'Category_Lvl1',
        rows: payload.catLvl1,
        columns: CatLvlPayload.catLvl1Columns,
        requiredColumns: const ['Cat_Code'],
      );

      final catLvl2 = await _upsertRows(
        txn,
        tableName: 'Category_Lvl2',
        rows: payload.catLvl2,
        columns: CatLvlPayload.catLvl2Columns,
        requiredColumns: const ['Cat_Code', 'Cat_Lv2_Code'],
      );

      final catLvl3 = await _upsertRows(
        txn,
        tableName: 'Category_Lvl3',
        rows: payload.catLvl3,
        columns: CatLvlPayload.catLvl3Columns,
        requiredColumns: const ['Cat_Code', 'Cat_Lv2_Code', 'Cat_Lv3_Code'],
      );

      return CatLvlSyncResult(
        catLvl1: catLvl1,
        catLvl2: catLvl2,
        catLvl3: catLvl3,
      );
    });
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

      final hasRequiredColumns = requiredColumns.every((column) {
        final value = normalizedRow[column];
        return value != null && value.toString().trim().isNotEmpty;
      });

      if (!hasRequiredColumns) continue;

      // Insert rows that do not yet exist, then update only the language
      // fields for existing rows. `replace` would delete Cat_Name while
      // saving Cat_Name2/Cat_Lv2_Name2.
      await txn.insert(
        tableName,
        normalizedRow,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await txn.update(
        tableName,
        normalizedRow,
        where: requiredColumns.map((column) => '$column = ?').join(' AND '),
        whereArgs: requiredColumns
            .map((column) => normalizedRow[column])
            .toList(),
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
    if (row.containsKey(columnName)) return row[columnName];

    // The language endpoints provide the translated name as `Cat_Name` /
    // `Cat_Lv2_Name`. Store those values in the matching *Name2 columns.
    final apiColumnNames = switch (columnName) {
      'Cat_Name2' => const ['Cat_Name'],
      'Cat_Lv2_Name2' => const [
          'Cat_Lv2_Name',
          'Cat_Lvl2_Name',
          'Cat_Lvl2_Name2',
          'Cat_Name',
        ],
      'Cat_Lv3_Name2' => const ['Cat_Lvl3_Name2'],
      _ => const <String>[],
    };
    for (final apiColumnName in apiColumnNames) {
      if (row.containsKey(apiColumnName)) {
        return row[apiColumnName];
      }
    }

    // API JSON uses lowercase/snake-case keys, for example `cat_name` and
    // `cat_lv2_name`; resolve the aliases using the same normalization used
    // for regular database columns.
    for (final apiColumnName in apiColumnNames) {
      final normalizedApiColumnName = _normalizeKey(apiColumnName);
      for (final entry in row.entries) {
        if (_normalizeKey(entry.key) == normalizedApiColumnName) {
          return entry.value;
        }
      }
    }

    final normalizedColumnName = _normalizeKey(columnName);

    for (final entry in row.entries) {
      if (_normalizeKey(entry.key) == normalizedColumnName) {
        return entry.value;
      }
    }

    return null;
  }

  String _normalizeKey(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
  }
}

class CatLvlPayload {
  const CatLvlPayload({
    this.catLvl1 = const [],
    this.catLvl2 = const [],
    this.catLvl3 = const [],
  });

  final List<Map<String, dynamic>> catLvl1;
  final List<Map<String, dynamic>> catLvl2;
  final List<Map<String, dynamic>> catLvl3;

  static const catLvl1Columns = {
    'Cat_Code',
    'Cat_Name2',
    'Cat_Type',
    'Color_Code',
    'Cat_Image',
    'Dine',
    'TakeAway',
    'Delivery',
    'Display_Order_ID',
  };

  static const catLvl2Columns = {
    'Cat_Code',
    'Cat_Lv2_Code',
    'Cat_Lv2_Name2',
    'Display_Order_ID',
  };

  static const catLvl3Columns = {
    'Cat_Code',
    'Cat_Lv2_Code',
    'Cat_Lv3_Code',
    'Cat_Lv3_Name2',
  };

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
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }
}

class CatLvlSyncResult {
  const CatLvlSyncResult({
    required this.catLvl1,
    required this.catLvl2,
    this.catLvl3 = 0,
  });

  final int catLvl1;
  final int catLvl2;
  final int catLvl3;

  int get total => catLvl1 + catLvl2 + catLvl3;
}
