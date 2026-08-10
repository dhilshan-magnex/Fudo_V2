import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:bcrypt/bcrypt.dart';

enum AppDatabase { fudo, sys }

class DBManager {
  static final Map<AppDatabase, Database> _databases = {};

  static Future<Database> getDatabase(AppDatabase dbType) async {
    if (_databases.containsKey(dbType)) {
      return _databases[dbType]!;
    }
    final db = await _openDatabase(dbType);
    _databases[dbType] = db;
    return db;
  }

  static Future<Database> _openDatabase(AppDatabase dbType) async {
    final dbPath = await getDatabasesPath();

    switch (dbType) {
      case AppDatabase.fudo:
        return _openAssetDatabase(
          fileName: 'Fudo.db',
          assetPath: 'assets/database/Fudo.db',
          dbPath: dbPath,
        );

      case AppDatabase.sys:
        return _openAssetDatabase(
          fileName: 'Sys.db',
          assetPath: 'assets/database/Sys.db',
          dbPath: dbPath,
          requiredTable: 'App_License',
          requiredColumns: const ['Client_ID', 'Client_Name'],
        );
    }
  }

  static Future<Database> _openAssetDatabase({
    required String fileName,
    required String assetPath,
    required String dbPath,
    String? requiredTable,
    List<String> requiredColumns = const [],
  }) async {
    final path = join(dbPath, fileName);
    final exists = await databaseExists(path);

    if (exists &&
        requiredTable != null &&
        !await _databaseHasColumns(path, requiredTable, requiredColumns)) {
      await deleteDatabase(path);
    }

    if (!await databaseExists(path)) {
      await Directory(dirname(path)).create(recursive: true);
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes, flush: true);
    }
    return openDatabase(path);
  }

  static Future<bool> _databaseHasColumns(
    String path,
    String tableName,
    List<String> columnNames,
  ) async {
    final db = await openDatabase(path, readOnly: true);
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
      final existingColumns = tableInfo
          .map((column) => column['name']?.toString())
          .whereType<String>()
          .toSet();

      return columnNames.every(existingColumns.contains);
    } finally {
      await db.close();
    }
  }

  // Generic fetch: all rows from any table in any database
  static Future<List<Map<String, dynamic>>> getTableData(
    AppDatabase dbType,
    String tableName,
  ) async {
    final db = await getDatabase(dbType);
    return db.query(tableName);
  }

  // Generic fetch with a WHERE condition
  static Future<List<Map<String, dynamic>>> getTableDataWhere(
    AppDatabase dbType,
    String tableName, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await getDatabase(dbType);
    return db.query(tableName, where: where, whereArgs: whereArgs);
  }

  static Future<Map<String, dynamic>?> getClientInfo() async {
    final rows = await getTableData(AppDatabase.sys, 'App_License');
    if (rows.isEmpty) return null;
    return rows.first;
  }

  // ---- Fudo.db specific: auth ----

  static Future<bool> validateLogin(String userId, String password) async {
    final result = await getTableDataWhere(
      AppDatabase.fudo,
      'User_File',
      where: '(User_ID = ? OR User_Name = ?) AND User_Active = ?',
      whereArgs: [userId, userId, 1],
    );

    if (result.isEmpty) return false;

    final storedPassword = (result.first['User_Pwd'] ?? '').toString();

    if (_isBcryptHash(storedPassword)) {
      return BCrypt.checkpw(password, storedPassword);
    }

    return password == storedPassword;
  }

  static bool _isBcryptHash(String value) {
    return value.startsWith(r'$2a$') ||
        value.startsWith(r'$2b$') ||
        value.startsWith(r'$2y$');
  }

  static Future<void> addUser({
    required String userId,
    required String userName,
    required String password,
    required String groupCode,
  }) async {
    final db = await getDatabase(AppDatabase.fudo);
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    await db.insert(
      'User_File',
      {
        'User_ID': userId,
        'User_Name': userName,
        'User_Pwd': hashedPassword,
        'Group_Code': groupCode,
        'User_Active': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
