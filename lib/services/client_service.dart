import '../database/db_manager.dart';
import '../database/sqlite_class.dart';
import '../session/api_session.dart';

class ClientService {
  Future<Map<String, dynamic>?> getClientInfo() async {
    final clientInfo = await SQLiteClass.getFirstTableRow(
      '001',
      AppDatabase.sys,
      'App_License',
    );

    if (clientInfo != null) {
      ApiSession.instance.startFromAppLicense(clientInfo);
    }

    return clientInfo;
  }
}
