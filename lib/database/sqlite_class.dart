import 'package:bcrypt/bcrypt.dart';
import 'db_manager.dart';

class SQLiteClass {
  static bool useSQLite = true;

  static Future<List<Map<String, dynamic>>> getTableData(
    AppDatabase dbType,
    String tableName, 
  ) async {
    if (useSQLite) {
      final db = await DBManager.getDatabase(dbType);
      return db.query(tableName);
    }

    return _getTableDataFromApi(dbType, tableName);
  }

  static Future<List<Map<String, dynamic>>> getTableDataWhere(
    AppDatabase dbType,
    String tableName, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    if (useSQLite) {
      final db = await DBManager.getDatabase(dbType);
      return db.query(tableName, where: where, whereArgs: whereArgs);
    }

    return _getTableDataWhereFromApi(
      dbType,
      tableName,
      where: where,
      whereArgs: whereArgs,
    );
  }

  static Future<Map<String, dynamic>?> getClientInfo() async {
    final rows = await getTableData(AppDatabase.sys, 'App_License');
    if (rows.isEmpty) return null;
    return rows.first;
  }

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

  static Future<List<Map<String, dynamic>>> _getTableDataFromApi(
    AppDatabase dbType,
    String tableName,
  ) async {
    return [];
  }

  static Future<List<Map<String, dynamic>>> _getTableDataWhereFromApi(
    AppDatabase dbType,
    String tableName, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    return [];
  }
}
