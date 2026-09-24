import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../session/api_config.dart';
import '../database/db_manager.dart';

class AppLicenseApi {
  AppLicenseApi({http.Client? client})
      : _client = client ?? http.Client();

  static const String appLicenseEndpoint = 'applicense';
 

  final http.Client _client;


  // Synchronizing License Data

  Future<AppLicenseSyncResult> syncAppLicense({
    String? apiUrl,
    Map<String, String>? headers,
    bool clearExistingData = false,
  }) async {
    final resolvedApiUrl = apiUrl ?? ApiConfig.url(appLicenseEndpoint);

    final rows = await _fetchAppLicenseRows(
      resolvedApiUrl,
      headers: headers,
    );

    if (rows.isEmpty) {
      throw Exception(
        'App License API returned no license rows: $resolvedApiUrl',
      );
    }

    final result = await saveAppLicenseRows(
      rows,
      clearExistingData: clearExistingData,
    );

    if (result.savedCount == 0) {
      throw Exception(
        'App License API returned rows, but none were valid to save',
      );
    }

    return result;
  }

  
  // Fetching API Data

  Future<List<Map<String, dynamic>>> _fetchAppLicenseRows(
    String apiUrl, {
    Map<String, String>? headers,
  }) async {
    if (apiUrl.trim().isEmpty) {
      throw Exception(
        'App License API URL is not configured',
      );
    }

    final response = await _client
        .get(
          Uri.parse(apiUrl),
          headers: headers,
        );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'App License API failed with status '
        '${response.statusCode}: $apiUrl',
      );
    }

    return AppLicensePayload.rowsFromJson(
      jsonDecode(response.body),
    );
  }


  // Saving to SQLite
  
  Future<AppLicenseSyncResult> saveAppLicenseRows(
    List<Map<String, dynamic>> rows, {
    bool clearExistingData = false,
  }) async {
    final db = await DBManager.getDatabase(
      AppDatabase.sys,
    );

    return db.transaction((txn) async {
      if (clearExistingData) {
        await txn.delete('App_License');
      }

      final savedCount = await _upsertRows(
        txn,
        rows,
      );

      return AppLicenseSyncResult(
        savedCount: savedCount,
      );
    });
  }


  // Row Validation  

  Future<int> _upsertRows(
    Transaction txn,
    List<Map<String, dynamic>> rows,
  ) async {
    var savedCount = 0;

    for (final row in rows) {
      final normalizedRow = _normalizeRow(row);

      final clientId = normalizedRow['Client_ID'];
      if (clientId == null ||
          clientId.toString().trim().isEmpty) {
        continue;
      }

      final clientName = normalizedRow['Client_Name'];
      if (clientName == null ||
          clientName.toString().trim().isEmpty) {
        normalizedRow['Client_Name'] = clientId.toString().trim();
      }

      await txn.insert(
        'App_License',
        normalizedRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      savedCount++;
    }

    return savedCount;
  }

 
  // Normalize Database Row

  Map<String, dynamic> _normalizeRow(
    Map<String, dynamic> row,
  ) {
    final normalizedRow = <String, dynamic>{};

    for (final column in AppLicensePayload.columns) {
      final value = _readValue(
        row,
        column,
      );

      if (value != null) {
        normalizedRow[column] = value;
      }
    }

    return normalizedRow;
  }

  dynamic _readValue(
    Map<String, dynamic> row,
    String columnName,
  ) {
    if (row.containsKey(columnName)) {
      return row[columnName];
    }

    final normalizedColumnName =
        _normalizeKey(columnName);

    for (final entry in row.entries) {
      if (_normalizeKey(entry.key) ==
          normalizedColumnName) {
        return entry.value;
      }
    }

    return null;
  }

  String _normalizeKey(String value) {
    return value
        .replaceAll(
          RegExp(r'[^A-Za-z0-9]'),
          '',
        )
        .toLowerCase();
  }
}


// App License Payload

class AppLicensePayload {
  static const columns = {
    'Client_ID',
    'Client_Name',
    'Start_Date',
    'Valid_To',
    'Last_Update',
    'Max_Version',
    'Key_Info',
    'Server_Info',
    'Client_Type',
    'Current_Version',
    'Activation_Server',
    'DB_Version',
  };

 
  // JSON Parsing
  
  static List<Map<String, dynamic>> rowsFromJson(
    dynamic json,
  ) {
    final root = _unwrapRoot(json);

    if (root is List) {
      return _asRows(root);
    }

    if (root is Map) {
      final map = Map<String, dynamic>.from(root);

      if (_looksLikeAppLicenseRow(map)) {
        return [map];
      }

      for (final value in map.values) {
        final rows = _asRows(value);

        if (rows.isNotEmpty) {
          return rows;
        }

        if (value is Map) {
          final row =
              Map<String, dynamic>.from(value);

          if (_looksLikeAppLicenseRow(row)) {
            return [row];
          }
        }
      }
    }

    return const [];
  }

 
  // Unwrap API Response
 
  static dynamic _unwrapRoot(dynamic json) {
    var current = json;

    while (current is Map) {
      final map =
          Map<String, dynamic>.from(current);

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

  // -------------------------
  // Check License Row
  // -------------------------

  static bool _looksLikeAppLicenseRow(
    Map<String, dynamic> row,
  ) {
    return _readValue(
          row,
          'Client_ID',
        ) !=
        null ||
        _readValue(
          row,
          'Client_Name',
        ) !=
        null;
  }

  static dynamic _readValue(
    Map<String, dynamic> row,
    String columnName,
  ) {
    if (row.containsKey(columnName)) {
      return row[columnName];
    }

    final normalizedColumnName =
        _normalizeKey(columnName);

    for (final entry in row.entries) {
      if (_normalizeKey(entry.key) ==
          normalizedColumnName) {
        return entry.value;
      }
    }

    return null;
  }

  // -------------------------
  // Convert List to Rows
  // -------------------------

  static List<Map<String, dynamic>> _asRows(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (row) =>
              Map<String, dynamic>.from(row),
        )
        .toList();
  }

  static String _normalizeKey(String value) {
    return value
        .replaceAll(
          RegExp(r'[^A-Za-z0-9]'),
          '',
        )
        .toLowerCase();
  }
}


// Sync Result

class AppLicenseSyncResult {
  const AppLicenseSyncResult({
    required this.savedCount,
  });

  final int savedCount;
}
