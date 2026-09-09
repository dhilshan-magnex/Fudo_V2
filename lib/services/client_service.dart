import '../database/db_manager.dart';
import '../database/sqlite_class.dart';

class ClientService {
  Future<Map<String, dynamic>?> getClientInfo() async {
    return SQLiteClass.getFirstTableRow('001', AppDatabase.sys, 'App_License');
  }
}
