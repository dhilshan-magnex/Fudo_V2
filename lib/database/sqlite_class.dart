import 'db_manager.dart';

class SQLiteClass {
  static Future<List<Map<String, dynamic>>> getTableData(
    String clientId,
    AppDatabase dbType,
    String tableName,
  ) async {
    final dataSource = DataSourceManager.getDataSource(clientId);

    if (dataSource == DataSource.sqlite) {
      final db = await DBManager.getDatabase(dbType);

      return await db.query(tableName);
    }

    return await _getTableDataFromApi(clientId, dbType, tableName);
  }

  static Future<List<Map<String, dynamic>>> getTableDataWhere(
    String clientId,
    AppDatabase dbType,
    String tableName, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final dataSource = DataSourceManager.getDataSource(clientId);

    if (dataSource == DataSource.sqlite) {
      final db = await DBManager.getDatabase(dbType);

      return await db.query(tableName, where: where, whereArgs: whereArgs);
    }

    return await _getTableDataWhereFromApi(
      clientId,
      dbType,
      tableName,
      where: where,
      whereArgs: whereArgs,
    );
  }

  static Future<Map<String, dynamic>?> getFirstTableRow(
    String clientId,
    AppDatabase dbType,
    String tableName, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final rows = await getTableDataWhere(
      clientId,
      dbType,
      tableName,
      where: where ?? '1 = 1',
      whereArgs: whereArgs ?? const [],
    );

    if (rows.isEmpty) return null;

    return rows.first;
  }

  static Future<List<Map<String, dynamic>>> _getTableDataFromApi(
    String clientId,
    AppDatabase dbType,
    String tableName,
  ) async {
    // Implement API request here

    return [];
  }

  static Future<List<Map<String, dynamic>>> _getTableDataWhereFromApi(
    String clientId,
    AppDatabase dbType,
    String tableName, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    //Implement API request here

    return [];
  }
}
