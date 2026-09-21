import 'api_route_registry.dart';
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

    return await _getTableDataFromApi(dbType, tableName);
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
    AppDatabase dbType,
    String tableName,
  ) async {
    await ApiRouteRegistry.syncTable(dbType, tableName);

    final db = await DBManager.getDatabase(dbType);
    return db.query(tableName);
  }

  static Future<List<Map<String, dynamic>>> _getTableDataWhereFromApi(
    AppDatabase dbType,
    String tableName, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    await ApiRouteRegistry.syncTable(dbType, tableName);

    final db = await DBManager.getDatabase(dbType);
    return db.query(tableName, where: where, whereArgs: whereArgs);
  }
}
