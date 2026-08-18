import '../database/db_manager.dart';
import '../database/sqlite_class.dart';

class ClientService {
  Future<Map<String, dynamic>?> getClientInfo() async {
    final rows = await SQLiteClass.getTableData(AppDatabase.sys, 'App_License');
    if (rows.isEmpty) return null;
    return rows.first;
  }
}
