import '../database/db_manager.dart';
import '../database/sqlite_class.dart';

class ClientService {
  Future<Map<String, dynamic>?> getClientInfo() async {
    final clientInfo = await SQLiteClass.getFirstTableRow(
      '001',
      AppDatabase.sys,
      'App_License',
    );

    return clientInfo;
  }
}
