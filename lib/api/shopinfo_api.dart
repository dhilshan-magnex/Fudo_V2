import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'api_config.dart';
import '../database/db_manager.dart';

class ShopInfoApi {
  ShopInfoApi({http.Client? client}) : _client = client ?? http.Client();

  static const String shopInfoEndpoint = 'shopinfo';

  final http.Client _client;

  Future<ShopInfoSyncResult> syncShopInfo({
    String? apiUrl,
    Map<String, String>? headers,
    bool clearExistingData = false,
  }) async {
    final rows = await _fetchRows(
      apiUrl ?? ApiConfig.url(ShopInfoApi.shopInfoEndpoint),
      headers: headers,
    );

    return saveShopInfoRows(
      rows,
      clearExistingData: clearExistingData,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRows(
    String apiUrl, {
    Map<String, String>? headers,
  }) async {
    if (apiUrl.trim().isEmpty) {
      throw Exception('Shop Info API URL is not configured');
    }

    final response = await _client.get(Uri.parse(apiUrl), headers: headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Shop Info API failed with status ${response.statusCode}: $apiUrl',
      );
    }

    return ShopInfoPayload.rowsFromJson(jsonDecode(response.body));
  }

  Future<ShopInfoSyncResult> saveShopInfoRows(
    List<Map<String, dynamic>> rows, {
    bool clearExistingData = false,
  }) async {
    final db = await DBManager.getDatabase(AppDatabase.fudo);

    return db.transaction((txn) async {
      if (clearExistingData) {
        await txn.delete('Shop_Info');
      }

      final savedCount = await _upsertRows(txn, rows);

      return ShopInfoSyncResult(savedCount: savedCount);
    });
  }

  Future<int> _upsertRows(
    Transaction txn,
    List<Map<String, dynamic>> rows,
  ) async {
    var savedCount = 0;

    for (final row in rows) {
      final normalizedRow = _normalizeRow(row);
      final locationId = normalizedRow['Location_ID'];

      if (locationId == null || locationId.toString().trim().isEmpty) {
        final clientId = normalizedRow['Client_ID'];
        if (clientId == null || clientId.toString().trim().isEmpty) {
          continue;
        }
      }

      await txn.insert(
        'Shop_Info',
        normalizedRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      savedCount++;
    }

    return savedCount;
  }

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
    final normalizedRow = <String, dynamic>{};

    for (final column in ShopInfoPayload.columns) {
      final value = _readValue(row, column);
      if (value != null) {
        normalizedRow[column] = value;
      }
    }

    return normalizedRow;
  }

  dynamic _readValue(Map<String, dynamic> row, String columnName) {
    if (row.containsKey(columnName)) return row[columnName];

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

class ShopInfoPayload {
  static const columns = {
    'Client_ID',
    'Location_ID',
    'Location_Name',
    'Location_Address1',
    'Location_Address2',
    'Location_Phone',
    'Location_Mobile',
    'Location_Email',
    'Footer_Message1',
    'Footer_Message2',
    'Footer_Message_L1',
    'Footer_Message2_L1',
    'Currency_Code',
    'Currency_Decimal',
    'Tax_Inclusive',
    'Service_Charge',
    'Delivery_Charge',
    'Sales_target',
  };

  static List<Map<String, dynamic>> rowsFromJson(dynamic json) {
    final root = _unwrapRoot(json);

    if (root is List) {
      return _asRows(root);
    }

    if (root is Map) {
      final map = Map<String, dynamic>.from(root);

      if (_looksLikeShopInfoRow(map)) {
        return [map];
      }

      for (final value in map.values) {
        final rows = _asRows(value);

        if (rows.isNotEmpty) {
          return rows;
        }

        if (value is Map) {
          final row = Map<String, dynamic>.from(value);
          if (_looksLikeShopInfoRow(row)) {
            return [row];
          }
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

  static bool _looksLikeShopInfoRow(Map<String, dynamic> row) {
    return _readValue(row, 'Client_ID') != null ||
        _readValue(row, 'Location_ID') != null ||
        _readValue(row, 'Location_Name') != null ||
        _readValue(row, 'Currency_Code') != null;
  }

  static dynamic _readValue(Map<String, dynamic> row, String columnName) {
    if (row.containsKey(columnName)) return row[columnName];

    final normalizedColumnName = _normalizeKey(columnName);

    for (final entry in row.entries) {
      if (_normalizeKey(entry.key) == normalizedColumnName) {
        return entry.value;
      }
    }

    return null;
  }

  static List<Map<String, dynamic>> _asRows(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static String _normalizeKey(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
  }
}

class ShopInfoSyncResult {
  const ShopInfoSyncResult({required this.savedCount});

  final int savedCount;
}
