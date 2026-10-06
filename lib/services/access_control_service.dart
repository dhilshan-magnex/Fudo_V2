import '../database/db_manager.dart';

class AccessControlService {
  AccessControlService._();

  static Future<bool> checkAccess({
    required String groupCode,
    required String screenId,
    required String functionId,
  }) async {
    // Administrators must not be blocked by a missing or out-of-date
    // per-screen row in a locally cached desktop database.
    if (_isAdministratorGroup(groupCode)) {
      return true;
    }

    final database = await DBManager.getDatabase(
      AppDatabase.fudo,
    );

    final rows = await database.query(
      'user_setup',
      columns: ['Access_Lvl'],
      where: '''
        UPPER(TRIM(Group_Code)) = UPPER(TRIM(?))
        AND UPPER(TRIM(Screen_ID)) = UPPER(TRIM(?))
        AND UPPER(TRIM(Function_ID)) = UPPER(TRIM(?))
      ''',
      whereArgs: [
        groupCode.trim(),
        screenId.trim(),
        functionId.trim(),
      ],
      limit: 1,
    );

    if (rows.isEmpty) {
      return false;
    }

    final accessLevel =
        int.tryParse(
          rows.first['Access_Lvl']?.toString().trim() ?? '',
        ) ??
        0;

    return accessLevel == 1;
  }

  static bool _isAdministratorGroup(String groupCode) {
    final normalized = groupCode
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    return normalized == 'ADMIN' ||
        normalized == 'ADMINISTRATOR' ||
        normalized == 'SUPERADMIN';
  }
}
