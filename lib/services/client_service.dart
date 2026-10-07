import '../database/db_manager.dart';

class ClientService {
  /// Reads the locally bundled license record used to establish a session.
  ///
  /// This cannot use [SQLiteClass]: its API path needs a session client ID,
  /// while the license record is what supplies that ID before login.
  Future<Map<String, dynamic>?> getClientInfo() async {
    return DBManager.getClientInfo();
  }
}
