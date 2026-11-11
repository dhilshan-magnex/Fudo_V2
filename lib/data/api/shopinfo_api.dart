import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_http_client.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/config/api_config.dart';
import '../../core/config/server_settings.dart';
import '../database/db_manager.dart';
import '../server/shopinfo_api.dart' as server;

class ShopInfoApi {
  ShopInfoApi({http.Client? client})
    : _client = client ?? ApiHttpClient.instance;

  static const String shopInfoEndpoint = 'shopinfo';

  final http.Client _client;

  Future<ShopInfoSyncResult> syncShopInfo({
    String? apiUrl,
    String? clientId,
    String? locationId,
    String? clientType,
    server.ShopInfoApi? serverApi,
    Database? database,
    Map<String, String>? headers,
    bool clearExistingData = false,
  }) async {
    if ((clientId == null) != (locationId == null)) {
      throw ArgumentError(
        'Client_ID and Location_ID must be supplied together.',
      );
    }
    final dataSource = DataSourceManager.getDataSource(clientType);
    final rows = await _fetchRows(
      apiUrl ??
          (clientId != null && locationId != null
              ? ApiConfig.urlForClient(
                  shopInfoEndpoint,
                  clientId: clientId,
                  locationId: locationId,
                )
              : ApiConfig.url(shopInfoEndpoint)),
      headers: headers,
    );

    if (dataSource == DataSource.api) {
      return saveShopInfoRowsOnServer(rows, serverApi: serverApi);
    }
    return saveShopInfoRows(
      rows,
      database: database,
      clearExistingData: clearExistingData,
    );
  }

  Future<ShopInfoSyncResult> saveShopInfoRowsOnServer(
    List<Map<String, dynamic>> rows, {
    server.ShopInfoApi? serverApi,
  }) async {
    final api =
        serverApi ??
        server.ShopInfoApi(
          client: _client,
          baseUrl: await ServerSettings.getBaseUrl(),
        );
    final existingRows = (await api.getShopInfo()).map(_normalizeRow).toList();
    var savedCount = 0;
    for (final source in rows) {
      final row = _normalizeRow(source);
      final clientId = row['Client_ID']?.toString().trim() ?? '';
      final locationId = row['Location_ID']?.toString().trim() ?? '';
      final locationName = row['Location_Name']?.toString().trim() ?? '';
      if (clientId.isEmpty || locationId.isEmpty || locationName.isEmpty) {
        continue;
      }
      if (existingRows.any((existing) => _sameShopInfo(row, existing))) {
        // The desired data is already persisted; repeated syncs must not
        // attempt another INSERT for the same shop.
        savedCount++;
        continue;
      }
      num number(String key, num fallback) =>
          num.tryParse(row[key]?.toString() ?? '') ?? fallback;
      await api.createShopInfo(
        clientId: clientId,
        locationId: locationId,
        locationName: locationName,
        locationAddress1: row['Location_Address1']?.toString(),
        locationAddress2: row['Location_Address2']?.toString(),
        locationPhone: row['Location_Phone']?.toString(),
        locationMobile: row['Location_Mobile']?.toString(),
        locationEmail: row['Location_Email']?.toString(),
        footerMessage1: row['Footer_Message1']?.toString(),
        footerMessage2: row['Footer_Message2']?.toString(),
        footerMessageL1: row['Footer_Message_L1']?.toString(),
        footerMessage2L1: row['Footer_Message2_L1']?.toString(),
        currencyCode: row['Currency_Code']?.toString(),
        currencyDecimal: number('Currency_Decimal', 2).toInt(),
        taxInclusive: row['Tax_Inclusive'] is bool
            ? (row['Tax_Inclusive'] == true ? 1 : 0)
            : number('Tax_Inclusive', 0).toInt(),
        serviceCharge: number('Service_Charge', 0),
        deliveryCharge: number('Delivery_Charge', 0),
        salesTarget: number('Sales_target', 0),
      );
      savedCount++;
      existingRows.add(row);
    }
    return ShopInfoSyncResult(savedCount: savedCount);
  }

  bool _sameShopInfo(Map<String, dynamic> desired, Map<String, dynamic> saved) {
    const numericDefaults = {
      'Currency_Decimal': 2,
      'Tax_Inclusive': 0,
      'Service_Charge': 0,
      'Delivery_Charge': 0,
      'Sales_target': 0,
    };
    for (final column in ShopInfoPayload.columns) {
      final expected = desired[column];
      final actual = saved[column];
      if (numericDefaults.containsKey(column)) {
        num? number(dynamic value) => value is bool
            ? (value ? 1 : 0)
            : num.tryParse(value?.toString() ?? '');
        if ((number(expected) ?? numericDefaults[column]) != number(actual)) {
          return false;
        }
      } else if (expected?.toString() != actual?.toString()) {
        return false;
      }
    }
    return true;
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
        'Shop Info API failed with status ${response.statusCode}.',
      );
    }

    return ShopInfoPayload.rowsFromJson(jsonDecode(response.body));
  }

  Future<ShopInfoSyncResult> saveShopInfoRows(
    List<Map<String, dynamic>> rows, {
    Database? database,
    bool clearExistingData = false,
  }) async {
    final db = database ?? await DBManager.getDatabase(AppDatabase.fudo);

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
