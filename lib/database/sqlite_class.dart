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
