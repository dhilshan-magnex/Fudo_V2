import '../../data/database/db_manager.dart';

class ServerSettings {
  ServerSettings._();

  static Future<String?> getBaseUrl() async {
    final info = await DBManager.getClientInfo();
    final value = info?['Server_Info']?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static Future<void> saveBaseUrl(String value) async {
    final database = await DBManager.getDatabase(AppDatabase.sys);
    final updated = await database.update('App_License', {
      'Server_Info': value.trim(),
    });
    if (updated == 0) {
      throw StateError(
        'Save the app license before setting the server address.',
      );
    }
  }
}
