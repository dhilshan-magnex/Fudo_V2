import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


//call sqlite or API
enum DataSource { sqlite, api }

class DataSourceManager {
  static DataSource getDataSource(String clientId) {
    if (clientId == '001') {
      return DataSource.sqlite;
    }

    return DataSource.api;
  }
}

enum AppDatabase { fudo, sys }

//database manager
class DBManager {
  static const Map<AppDatabase, _DatabaseConfig> _configs = {
    AppDatabase.fudo: _DatabaseConfig(
      fileName: 'Fudo.db',
      assetPath: 'assets/database/Fudo.db',
    ),
    AppDatabase.sys: _DatabaseConfig(
      fileName: 'Sys.db',
      assetPath: 'assets/database/Sys.db',
      requiredTable: 'App_License',
      requiredColumns: ['Client_ID', 'Client_Name'],
    ),
  };

  static final Map<AppDatabase, Database> _databases = {};

  static Future<Database> getDatabase(AppDatabase dbType) async {
    final existingDatabase = _databases[dbType];
    if (existingDatabase != null) return existingDatabase;

    final database = await _openDatabase(dbType);
    _databases[dbType] = database;
    return database;
  }

  //authservice
  
  static Future<Map<String, dynamic>?> getClientInfo() async {
    final database = await getDatabase(AppDatabase.sys);
    final rows = await database.query('App_License');

    if (rows.isEmpty) return null;

    return rows.first;
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
      await deleteDatabase(databasePath);
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
