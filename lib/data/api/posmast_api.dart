import 'package:fudo_v2/core/config/server_settings.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_http_client.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/config/api_config.dart';
import '../../core/session/session_provider.dart';
import '../database/db_manager.dart';
import '../server/posprinter_api.dart';

class PosMastApi {
  PosMastApi({http.Client? client})
    : _client = client ?? ApiHttpClient.instance;

  static const String posMastEndpoint = 'posmast';

  final http.Client _client;

  Future<List<Map<String, dynamic>>> fetchPosMast({
    required String clientId,
    required String locationId,
  }) async {
    final rows = await _fetchRows(
      ApiConfig.urlForClient(
        posMastEndpoint,
        clientId: clientId,
        locationId: locationId,
      ),
    );
    return rows.map((row) => {...row, ..._normalizeRow(row)}).toList();
  }

  Future<PosMastSyncResult> syncPosMast({
    String? apiUrl,
    String? clientId,
    String? locationId,
    Map<String, String>? headers,
    bool clearExistingData = false,
    String? clientType,
    PosPrinterApi? serverApi,
    bool registerCounters = true,
  }) async {
    if ((clientId == null) != (locationId == null)) {
      throw ArgumentError(
        'Client_ID and Location_ID must be supplied together.',
      );
    }
    final resolvedApiUrl =
        apiUrl ??
        (clientId != null && locationId != null
            ? ApiConfig.urlForClient(
                posMastEndpoint,
                clientId: clientId,
                locationId: locationId,
              )
            : ApiConfig.url(posMastEndpoint));

    final rows = await _fetchRows(resolvedApiUrl, headers: headers);

    final resolvedClientType = (clientType ?? SessionProvider.currentClientType)
        .trim();
    final syncResult = switch (resolvedClientType) {
      '1' => await savePosMastRows(rows, clearExistingData: clearExistingData),
      '2' => await savePosMastRowsOnServer(rows, serverApi: serverApi),
      _ => throw StateError(
        'Unsupported Client_Type "$resolvedClientType" for POS_Mast.',
      ),
    };
    if (registerCounters) {
      final resolvedLocationId =
          locationId ?? SessionProvider.currentLocationId;
      final counterNumbers = rows
          .map((row) => _readValue(row, 'Counter_No')?.toString() ?? '')
          .toSet();
      await DBManager.registerCounters(
        counterNumbers: counterNumbers,
        locationId: resolvedLocationId,
      );
    }

    return PosMastSyncResult(
      savedCount: syncResult.savedCount,
      rows: rows.map(_normalizeRow).toList(),
    );
  }

  /// Sends fetched POS_Mast rows to the Node API for persistence in its
  /// Configure [serverSaveUrl] with the POST endpoint that
  /// accepts `{ "data": [...] }`.
  Future<PosMastSyncResult> savePosMastRowsOnServer(
    List<Map<String, dynamic>> rows, {
    PosPrinterApi? serverApi,
  }) async {
    final api =
        serverApi ??
        PosPrinterApi(
          client: _client,
          baseUrl: await ServerSettings.getBaseUrl(),
        );
    var savedCount = 0;
    for (final row in rows) {
      final counterNo = _readValue(row, 'Counter_No')?.toString().trim() ?? '';
      final counterName =
          _readValue(row, 'Counter_Name')?.toString().trim() ?? '';
      final receiptCode =
          _readValue(row, 'Receipt_Code')?.toString().trim().isNotEmpty == true
          ? _readValue(row, 'Receipt_Code').toString().trim()
          : _readValue(row, 'Receipt_Prn_Code')?.toString().trim() ?? '';
      if (counterNo.isEmpty || counterName.isEmpty || receiptCode.isEmpty) {
        continue;
      }
      final existingRows = await api.getPos(counterNo);
      if (existingRows.any(
        (existing) =>
            _readValue(existing, 'Counter_No')?.toString().trim() == counterNo,
      )) {
        savedCount++;
        continue;
      }
      await api.createPos(
        counterNo: counterNo,
        counterName: counterName,
        receiptCode: receiptCode,
        cashDrawerCode: _readValue(row, 'Cash_Drawer_Code')?.toString(),
        customerDisplayCode:
            _readValue(row, 'Cus_Display_Code')?.toString() ??
            _readValue(row, 'Customer_Display_Code')?.toString(),
      );
      savedCount++;
    }
    return PosMastSyncResult(savedCount: savedCount);
  }

  Future<List<Map<String, dynamic>>> _fetchRows(
    String apiUrl, {
    Map<String, String>? headers,
  }) async {
    if (apiUrl.trim().isEmpty) {
      throw Exception('POS Mast API URL is not configured');
    }

    final response = await _client.get(Uri.parse(apiUrl), headers: headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'POS Mast API failed with status ${response.statusCode}.',
      );
    }

    return PosMastPayload.rowsFromJson(jsonDecode(response.body));
  }

  Future<PosMastSyncResult> savePosMastRows(
    List<Map<String, dynamic>> rows, {
    bool clearExistingData = false,
  }) async {
    final db = await DBManager.getDatabase(AppDatabase.fudo);

    return db.transaction((txn) async {
      if (clearExistingData) {
        await txn.delete('POS_Mast');
      }

      final savedCount = await _upsertRows(txn, rows);

      return PosMastSyncResult(savedCount: savedCount);
    });
  }

  Future<int> _upsertRows(
    Transaction txn,
    List<Map<String, dynamic>> rows,
  ) async {
    var savedCount = 0;

    for (final row in rows) {
      final normalizedRow = _normalizeRow(row);
      final counterNo = normalizedRow['Counter_No'];

      if (counterNo == null || counterNo.toString().trim().isEmpty) {
        continue;
      }

      await txn.insert(
        'POS_Mast',
        normalizedRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      savedCount++;
    }

    return savedCount;
  }

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
    final normalizedRow = <String, dynamic>{};

    for (final column in PosMastPayload.columns) {
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

class PosMastPayload {
  static const columns = {
    'Counter_No',
    'Counter_Name',
    'Receipt_Prn_Code',
    'Cash_Drawer_Code',
    'Customer_Display_Code',
  };

  static List<Map<String, dynamic>> rowsFromJson(dynamic json) {
    final root = _unwrapRoot(json);

    if (root is List) {
      return _asRows(root);
    }

    if (root is Map) {
      final map = Map<String, dynamic>.from(root);

      if (_looksLikePosMastRow(map)) {
        return [map];
      }

      for (final value in map.values) {
        final rows = _asRows(value);

        if (rows.isNotEmpty) {
          return rows;
        }

        if (value is Map) {
          final row = Map<String, dynamic>.from(value);
          if (_looksLikePosMastRow(row)) {
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

  static bool _looksLikePosMastRow(Map<String, dynamic> row) {
    return _readValue(row, 'Counter_No') != null ||
        _readValue(row, 'Counter_Name') != null ||
        _readValue(row, 'Receipt_Prn_Code') != null ||
        _readValue(row, 'Cash_Drawer_Code') != null ||
        _readValue(row, 'Customer_Display_Code') != null;
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

class PosMastSyncResult {
  const PosMastSyncResult({required this.savedCount, this.rows = const []});

  final int savedCount;
  final List<Map<String, dynamic>> rows;
}
