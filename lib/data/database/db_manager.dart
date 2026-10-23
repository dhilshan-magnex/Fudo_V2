import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Selects whether a client uses local SQLite data or the API.
enum DataSource { sqlite, api }

class DataSourceManager {
  static DataSource getDataSource(String clientId) {
    if (clientId == '940T0003') {
      return DataSource.sqlite;
    }

    return DataSource.api;
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
      if (dbType == AppDatabase.sys) {
        await _ensureDefaultCounter(database);
      }
      _databases[dbType] = database;
      return database;
    } finally {
      _openingDatabases.remove(dbType);
    }
  }

  static Future<Map<String, dynamic>?> getClientInfo() async {
    final database = await getDatabase(AppDatabase.sys);
    final rows = await database.query('App_License');

    if (rows.isEmpty) return null;

    return rows.first;
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

  static Future<Map<String, dynamic>?> getUserForLogin(
    String clientId,
    String userId,
  ) async {
    if (DataSourceManager.getDataSource(clientId) != DataSource.sqlite) {
      return null;
    }

    final database = await getDatabase(AppDatabase.fudo);
    final trimmedUserId = userId.trim();
    final rows = await database.query(
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

    return openDatabase(databasePath);
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

  /// Ensures the starter counter is also present in an already-copied Sys.db.
  /// Asset changes alone do not update a database that was created on a
  /// previous app launch.
  static Future<void> _ensureDefaultCounter(Database database) => database.insert(
    'Counter_Info',
    {
      'Counter_No': '01',
      'Location_ID': '002',
      'POS_ID': 'POS-001',
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

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
