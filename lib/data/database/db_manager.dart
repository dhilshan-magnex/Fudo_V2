import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fudo_v2/core/session/session_provider.dart';
import '../server/users_api.dart';

// Client type 1 uses local SQLite; client type 2 uses the server API.
enum DataSource { sqlite, api }

class DataSourceManager {
  static DataSource getDataSource([String? clientType]) {
    final resolvedClientType = (clientType ?? SessionProvider.currentClientType)
        .trim();
    return switch (resolvedClientType) {
      '1' => DataSource.sqlite,
      '2' => DataSource.api,
      _ => throw StateError(
        'Unsupported client type "$resolvedClientType". Expected 1 (SQLite) or 2 (server API).',
      ),
    };
  }
}

enum AppDatabase { fudo, sys }

class _DatabaseConfig {
  const _DatabaseConfig({
    required this.fileName,
    required this.assetPath,
    this.requiredTable,
    this.requiredColumns = const [],
  });

  final String fileName;
  final String assetPath;
  final String? requiredTable;
  final List<String> requiredColumns;
}

//Database manager
class DBManager {
  static const Map<AppDatabase, _DatabaseConfig> _configs = {
    AppDatabase.fudo: _DatabaseConfig(
      fileName: 'Fudo.db',
      assetPath: 'assets/database/Fudo.db',
      requiredTable: 'User_File',
      requiredColumns: ['User_ID', 'User_Name', 'User_Pwd', 'User_Active'],
    ),
    AppDatabase.sys: _DatabaseConfig(
      fileName: 'Sys.db',
      assetPath: 'assets/database/Sys.db',
      requiredTable: 'App_License',
      requiredColumns: ['Client_ID', 'Client_Name'],
    ),
  };

  // Cache open databases and prevent concurrent initialization.
  static final Map<AppDatabase, Database> _databases = {};
  static final Map<AppDatabase, Future<Database>> _openingDatabases = {};

  static Future<Database> getDatabase(AppDatabase dbType) async {
    final existingDatabase = _databases[dbType];
    if (existingDatabase != null) return existingDatabase;

    final openingDatabase = _openingDatabases.putIfAbsent(
      dbType,
      () => _openDatabase(dbType),
    );

    try {
      final database = await openingDatabase;
      _databases[dbType] = database;
      return database;
    } finally {
      _openingDatabases.remove(dbType);
    }
  }

  static Future<Map<String, dynamic>?> getClientInfo() async {
    final database = await getDatabase(AppDatabase.sys);
    final rows = await database.query('App_License');
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  static Future<void> setInitialSetupComplete(
    bool complete, {
    Database? database,
  }) async {
    final db = database ?? await getDatabase(AppDatabase.sys);
    await db.execute(
      'CREATE TABLE IF NOT EXISTS Device_Setup_Status '
      '(ID INTEGER PRIMARY KEY, Complete INTEGER NOT NULL)',
    );
    await db.insert('Device_Setup_Status', {
      'ID': 1,
      'Complete': complete ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<bool> isInitialSetupComplete({Database? database}) async {
    database ??= await getDatabase(AppDatabase.sys);
    await database.execute(
      'CREATE TABLE IF NOT EXISTS Device_Setup_Status '
      '(ID INTEGER PRIMARY KEY, Complete INTEGER NOT NULL)',
    );
    final status = await database.query('Device_Setup_Status', limit: 1);
    if (status.isNotEmpty && status.first['Complete'] != 1) return false;
    // Preserve existing installations that predate the completion marker.
    final licenseRows = await database.query('App_License', limit: 1);
    final counterRows = await database.query('Counter_Info', limit: 1);
    return licenseRows.isNotEmpty && counterRows.isNotEmpty;
  }

  /// Returns the configured location for the POS counter currently in use.
  static Future<Map<String, dynamic>?> getCounterInfo({
    String counterNo = '01',
  }) async {
    final database = await getDatabase(AppDatabase.sys);
    final rows = await database.query(
      'Counter_Info',
      where: 'Counter_No = ?',
      whereArgs: [counterNo],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  static Future<List<Map<String, dynamic>>> getCounterInfos() async {
    final database = await getDatabase(AppDatabase.sys);
    return database.query('Counter_Info', orderBy: 'Counter_No ASC');
  }

  static Future<void> saveSelectedCounterInfo(
    Map<String, dynamic> counterInfo,
  ) async {
    final counterNo = counterInfo['Counter_No']?.toString().trim() ?? '';
    final locationId = counterInfo['Location_ID']?.toString().trim() ?? '';
    if (counterNo.isEmpty || locationId.isEmpty) {
      throw ArgumentError(
        'The selected counter is missing required information.',
      );
    }

    final database = await getDatabase(AppDatabase.sys);
    final existing = await database.query(
      'Counter_Info',
      columns: ['Counter_No'],
      where: 'Counter_No = ?',
      whereArgs: [counterNo],
      limit: 1,
    );
    final values = {
      'Counter_No': counterNo,
      'Location_ID': locationId,
      if (counterInfo['POS_ID'] != null) 'POS_ID': counterInfo['POS_ID'],
    };

    if (existing.isEmpty) {
      await database.insert('Counter_Info', values);
    } else {
      await database.update(
        'Counter_Info',
        values..remove('Counter_No'),
        where: 'Counter_No = ?',
        whereArgs: [counterNo],
      );
    }
  }

  static Future<void> registerCounters({
    required Iterable<String> counterNumbers,
    required String locationId,
  }) async {
    final normalizedLocationId = locationId.trim();
    final counters = counterNumbers
        .map((counterNo) => counterNo.trim())
        .where((counterNo) => counterNo.isNotEmpty)
        .toSet();
    if (normalizedLocationId.isEmpty) {
      throw ArgumentError('Location_ID is required to register counters.');
    }
    if (counters.isEmpty) return;

    final database = await getDatabase(AppDatabase.sys);
    await database.transaction((txn) async {
      for (final counterNo in counters) {
        final existing = await txn.query(
          'Counter_Info',
          columns: ['Counter_No'],
          where: 'Counter_No = ?',
          whereArgs: [counterNo],
          limit: 1,
        );
        if (existing.isEmpty) {
          await txn.insert('Counter_Info', {
            'Counter_No': counterNo,
            'Location_ID': normalizedLocationId,
          });
        } else {
          await txn.update(
            'Counter_Info',
            {'Location_ID': normalizedLocationId},
            where: 'Counter_No = ?',
            whereArgs: [counterNo],
          );
        }
      }
    });
  }

  static Future<Map<String, dynamic>?> getUserForLogin(
    String clientType,
    String userId, {
    Database? database,
    UsersApi? usersApi,
  }) async {
    if (DataSourceManager.getDataSource(clientType) == DataSource.api) {
      final rows = await (usersApi ?? UsersApi()).getUsers();
      final loginId = userId.trim();
      for (final row in rows) {
        final fields = {
          for (final entry in row.entries) entry.key.toLowerCase(): entry.value,
        };
        final active = fields['user_active'];
        if ((active == true || active.toString() == '1') &&
            (fields['user_id']?.toString() == loginId ||
                fields['user_name']?.toString() == loginId)) {
          return {
            ...row,
            for (final column in [
              'User_ID',
              'User_Name',
              'User_Pwd',
              'User_Active',
              'Group_Code',
              'Group_Name',
            ])
              if (fields.containsKey(column.toLowerCase()))
                column: fields[column.toLowerCase()],
          };
        }
      }
      return null;
    }

    final loginDatabase = database ?? await getDatabase(AppDatabase.fudo);
    final trimmedUserId = userId.trim();
    final rows = await loginDatabase.query(
      'User_File',
      where: '''
        (CAST(User_ID AS TEXT) = ? OR User_Name = ?)
        AND User_Active = ?
      ''',
      whereArgs: [trimmedUserId, trimmedUserId, 1],
    );

    if (rows.isEmpty) return null;

    return rows.first;
  }

  static Future<Database> _openDatabase(AppDatabase dbType) async {
    final config = _configs[dbType]!;

    final databaseDirectory = await getDatabasesPath();
    final databasePath = join(databaseDirectory, config.fileName);

    await _refreshInvalidDatabase(databasePath, config);

    await _copyAssetDatabaseIfMissing(databasePath, config.assetPath);

    final database = await openDatabase(databasePath);
    await _applySchemaUpdates(dbType, database);
    return database;
  }

  /// Applies additive schema updates required by newer app versions.
  static Future<void> _applySchemaUpdates(
    AppDatabase dbType,
    Database database,
  ) async {
    if (dbType == AppDatabase.sys) {
      final columns = await database.rawQuery('PRAGMA table_info(App_License)');
      if (!columns.any((column) => column['name'] == 'Server_Info')) {
        await database.execute(
          'ALTER TABLE App_License ADD COLUMN Server_Info TEXT',
        );
      }
      final legacyFile = File(
        join(dirname(database.path), 'server_address.txt'),
      );
      String? legacyAddress;
      if (await legacyFile.exists()) {
        legacyAddress = (await legacyFile.readAsString()).trim();
      }
      await database.execute('DROP TABLE IF EXISTS App_Setup');
      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'App_Config'",
      );
      if (tables.isNotEmpty) {
        final rows = await database.query(
          'App_Config',
          columns: ['Config_Value'],
          where: 'Config_Key = ?',
          whereArgs: ['POS_PRINTER_API_BASE_URL'],
          limit: 1,
        );
        if ((legacyAddress == null || legacyAddress.isEmpty) &&
            rows.isNotEmpty) {
          legacyAddress = rows.first['Config_Value']?.toString().trim();
        }
      }
      if (legacyAddress != null && legacyAddress.isNotEmpty) {
        final rows = await database.query('App_License', limit: 1);
        if (rows.isEmpty) return;
        await database.update('App_License', {'Server_Info': legacyAddress});
        if (await legacyFile.exists()) await legacyFile.delete();
      }
      if (tables.isNotEmpty) await database.execute('DROP TABLE App_Config');
      return;
    }

    final columns = await database.rawQuery('PRAGMA table_info(Tran_Header)');
    final hasBillTime = columns.any(
      (column) => column['name']?.toString() == 'Bill_Time',
    );
    if (!hasBillTime) {
      await database.execute(
        'ALTER TABLE Tran_Header ADD COLUMN Bill_Time TEXT',
      );
    }
  }

  static Future<void> _refreshInvalidDatabase(
    String databasePath,
    _DatabaseConfig config,
  ) async {
    if (config.requiredTable == null) return;
    if (!await databaseExists(databasePath)) return;

    final hasRequiredColumns = await _databaseHasColumns(
      databasePath,
      config.requiredTable!,
      config.requiredColumns,
    );

    if (!hasRequiredColumns) {
      throw StateError(
        'Local database schema is incompatible. A data migration is required.',
      );
    }
  }

  static Future<void> _copyAssetDatabaseIfMissing(
    String databasePath,
    String assetPath,
  ) async {
    if (await databaseExists(databasePath)) return;

    await Directory(dirname(databasePath)).create(recursive: true);

    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    await File(databasePath).writeAsBytes(bytes, flush: true);
  }

  static Future<bool> _databaseHasColumns(
    String databasePath,
    String tableName,
    List<String> columnNames,
  ) async {
    final database = await openDatabase(databasePath, readOnly: true);
    try {
      final tableInfo = await database.rawQuery(
        'PRAGMA table_info($tableName)',
      );
      final existingColumns = tableInfo
          .map((column) => column['name']?.toString())
          .whereType<String>()
          .toSet();

      return columnNames.every(existingColumns.contains);
    } finally {
      await database.close();
    }
  }
}
