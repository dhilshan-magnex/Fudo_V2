import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../database/db_manager.dart';
import '../session/api_session.dart';

class SectionMasterApi {
  SectionMasterApi({http.Client? client}) : _client = client ?? http.Client();

  static const String sectionMasterEndpoint = 'sectionmaster';

  final http.Client _client;

  Future<SectionMasterSyncResult> syncSectionMaster({
    String? apiUrl,
    Map<String, String>? headers,
    bool clearExistingData = false,
  }) async {
    final rows = await _fetchRows(
      apiUrl ?? ApiSession.instance.urlFor(SectionMasterApi.sectionMasterEndpoint),
      headers: headers,
    );

    return saveSectionMasterRows(
      rows,
      clearExistingData: clearExistingData,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRows(
    String apiUrl, {
    Map<String, String>? headers,
  }) async {
    if (apiUrl.trim().isEmpty) {
      throw Exception('Section Master API URL is not configured');
    }

    final response = await _client.get(Uri.parse(apiUrl), headers: headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Section Master API failed with status ${response.statusCode}: $apiUrl',
      );
    }

    return SectionMasterPayload.rowsFromJson(jsonDecode(response.body));
  }

  Future<SectionMasterSyncResult> saveSectionMasterRows(
    List<Map<String, dynamic>> rows, {
    bool clearExistingData = false,
  }) async {
    final db = await DBManager.getDatabase(AppDatabase.fudo);

    return db.transaction((txn) async {
      if (clearExistingData) {
        await txn.delete('Section_Master');
      }

      final savedCount = await _upsertRows(txn, rows);

      return SectionMasterSyncResult(savedCount: savedCount);
    });
  }

  Future<int> _upsertRows(
    Transaction txn,
    List<Map<String, dynamic>> rows,
  ) async {
    var savedCount = 0;

    for (final row in rows) {
      final normalizedRow = _normalizeRow(row);
      final sectionId = normalizedRow['Section_ID'];

      if (sectionId == null || sectionId.toString().trim().isEmpty) {
        continue;
      }

      await txn.insert(
        'Section_Master',
        normalizedRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      savedCount++;
    }

    return savedCount;
  }

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
    final normalizedRow = <String, dynamic>{};

    for (final column in SectionMasterPayload.columns) {
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

class SectionMasterPayload {
  static const columns = {
    'Section_ID',
    'Section_Name',
    'Section_Order',
  };

  static List<Map<String, dynamic>> rowsFromJson(dynamic json) {
    final root = _unwrapRoot(json);

    if (root is List) {
      return _asRows(root);
    }

    if (root is Map) {
      final map = Map<String, dynamic>.from(root);

      if (_looksLikeSectionMasterRow(map)) {
        return [map];
      }

      for (final value in map.values) {
        final rows = _asRows(value);

        if (rows.isNotEmpty) {
          return rows;
        }

        if (value is Map) {
          final row = Map<String, dynamic>.from(value);
          if (_looksLikeSectionMasterRow(row)) {
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

  static bool _looksLikeSectionMasterRow(Map<String, dynamic> row) {
    return _readValue(row, 'Section_ID') != null ||
        _readValue(row, 'Section_Name') != null ||
        _readValue(row, 'Section_Order') != null;
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

class SectionMasterSyncResult {
  const SectionMasterSyncResult({required this.savedCount});

  final int savedCount;
}
