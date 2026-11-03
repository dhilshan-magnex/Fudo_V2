import '../synchronization/api_route_registry.dart';
import '../database/db_manager.dart';

class SQLiteClass {

  // GET ALL TABLE DATA
  static Future<List<Map<String, dynamic>>> getTableData(
    String clientType,
    AppDatabase dbType,
    String tableName,
  ) async {
    final dataSource = DataSourceManager.getDataSource(clientType);

    // SQLITE CLIENT

    if (dataSource == DataSource.sqlite) {
      final db = await DBManager.getDatabase(dbType);
      return db.query(tableName);
    }

    // API CLIENT

    await _syncTableFromApi(dbType, tableName);
    final db = await DBManager.getDatabase(dbType);
    return db.query(tableName);
  }


  // GET DATA WITH WHERE CONDITION
  static Future<List<Map<String, dynamic>>> getTableDataWhere(
    String clientType,
    AppDatabase dbType,
    String tableName, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final dataSource = DataSourceManager.getDataSource(clientType);

    // SQLITE CLIENT

    if (dataSource == DataSource.sqlite) {
      final db = await DBManager.getDatabase(dbType);

      return db.query(tableName, where: where, whereArgs: whereArgs);
    }

    // API CLIENT

    await _syncTableFromApi(dbType, tableName);
    final db = await DBManager.getDatabase(dbType);
    return db.query(tableName, where: where, whereArgs: whereArgs);
  }

  static Future<Map<String, dynamic>?> getFirstTableRow(
    String clientType,
    AppDatabase dbType,
    String tableName, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final rows = await getTableDataWhere(
      clientType,
      dbType,
      tableName,
      where: where ?? '1 = 1',
      whereArgs: whereArgs ?? const [],
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

 
  // API SYNCHRONIZATION

  static Future<void> _syncTableFromApi(
    AppDatabase dbType,
    String tableName,
  ) async {
    await ApiRouteRegistry.syncTable(dbType, tableName);
  }
}
