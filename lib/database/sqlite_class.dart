import 'api_route_registry.dart';
import 'db_manager.dart';

class SQLiteClass {
  // ============================================================
  // GET ALL TABLE DATA
  // ============================================================

  /// Returns all rows from the requested table.
  ///
  /// For SQLite clients:
  ///     Reads directly from the local SQLite database.
  ///
  /// For API clients:
  ///     ApiRouteRegistry determines which API should
  ///     synchronize the requested table.
  ///     After synchronization, the data is read from SQLite.
  static Future<List<Map<String, dynamic>>> getTableData(
    String clientId,
    AppDatabase dbType,
    String tableName,
  ) async {
    final dataSource =
        DataSourceManager.getDataSource(clientId);

    // ------------------------------------------------------------
    // SQLITE CLIENT
    // ------------------------------------------------------------

    if (dataSource == DataSource.sqlite) {
      final db = await DBManager.getDatabase(dbType);

      return db.query(tableName);
    }

    // ------------------------------------------------------------
    // API CLIENT
    // ------------------------------------------------------------

    await _syncTableFromApi(
      dbType,
      tableName,
    );

    // After API synchronization,
    // read the synchronized data from SQLite.
    final db = await DBManager.getDatabase(dbType);

    return db.query(tableName);
  }

  // ============================================================
  // GET DATA WITH WHERE CONDITION
  // ============================================================

  /// Returns rows from the requested table using a WHERE condition.
  ///
  /// Example:
  ///
  /// final rows = await SQLiteClass.getTableDataWhere(
  ///   clientId,
  ///   AppDatabase.fudo,
  ///   'Category_Lvl1',
  ///   where: 'Cat_Code = ?',
  ///   whereArgs: ['001'],
  /// );
  static Future<List<Map<String, dynamic>>> getTableDataWhere(
    String clientId,
    AppDatabase dbType,
    String tableName, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final dataSource =
        DataSourceManager.getDataSource(clientId);

    // ------------------------------------------------------------
    // SQLITE CLIENT
    // ------------------------------------------------------------

    if (dataSource == DataSource.sqlite) {
      final db = await DBManager.getDatabase(dbType);

      return db.query(
        tableName,
        where: where,
        whereArgs: whereArgs,
      );
    }

    // ------------------------------------------------------------
    // API CLIENT
    // ------------------------------------------------------------

    await _syncTableFromApi(
      dbType,
      tableName,
    );

    // Read synchronized data from SQLite.
    final db = await DBManager.getDatabase(dbType);

    return db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
    );
  }

  // ============================================================
  // GET FIRST ROW
  // ============================================================

  /// Returns the first matching row.
  ///
  /// Returns null if no matching row exists.
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

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  // ============================================================
  // API SYNCHRONIZATION
  // ============================================================

  /// Requests synchronization for the specified table.
  ///
  /// SQLiteClass does not know which API handles the table.
  /// ApiRouteRegistry is responsible for deciding that.
  static Future<void> _syncTableFromApi(
    AppDatabase dbType,
    String tableName,
  ) async {
    await ApiRouteRegistry.syncTable(
      dbType,
      tableName,
    );
  }
}

