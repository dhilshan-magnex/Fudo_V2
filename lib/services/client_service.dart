import '../database/db_manager.dart';

class ClientService {
  Future<Map<String, dynamic>?> getClientInfo() async {
    final db = await DBManager.getDatabase(AppDatabase.sys);

    final rows = await db.query('App_License');

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }
}