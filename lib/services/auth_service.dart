import 'package:bcrypt/bcrypt.dart';
import '../database/db_manager.dart';
import '../database/sqlite_class.dart';

class AuthService {
  Future<Map<String, dynamic>?> validateLogin(
    String clientId,
    String userId,
    String password,
  ) async {
    final result = await SQLiteClass.getTableDataWhere(
      clientId,
      AppDatabase.fudo,
      'User_File',
      where: '''
        (CAST(User_ID AS TEXT) = ? OR User_Name = ?)
        AND User_Active = ?
      ''',
      whereArgs: [userId.trim(), userId.trim(), 1],
    );

    if (result.isEmpty) {
      return null;
    }

    final user = result.first;

    final storedPassword =
        (user['User_Pwd'] ?? '').toString();

    bool passwordValid;

    if (_isBcryptHash(storedPassword)) {
      passwordValid = BCrypt.checkpw(
        password,
        storedPassword,
      );
    } else {
      passwordValid = password == storedPassword;
    }

    if (!passwordValid) {
      return null;
    }

    return user;
  }

  bool _isBcryptHash(String value) {
    return value.startsWith(r'$2a$') ||
        value.startsWith(r'$2b$') ||
        value.startsWith(r'$2y$');
  }
}