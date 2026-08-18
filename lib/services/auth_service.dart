import 'package:bcrypt/bcrypt.dart';
import '../database/db_manager.dart';
import '../database/sqlite_class.dart';

class AuthService {
  Future<bool> validateLogin(String userId, String password) async {
    final result = await SQLiteClass.getTableDataWhere(
      AppDatabase.fudo,
      'User_File',
      where: '(User_ID = ? OR User_Name = ?) AND User_Active = ?',
      whereArgs: [userId, userId, 1],
    );

    if (result.isEmpty) return false;

    final storedPassword = (result.first['User_Pwd'] ?? '').toString();

    if (_isBcryptHash(storedPassword)) {
      return BCrypt.checkpw(password, storedPassword);
    }

    return password == storedPassword;
  }

  bool _isBcryptHash(String value) {
    return value.startsWith(r'$2a$') ||
        value.startsWith(r'$2b$') ||
        value.startsWith(r'$2y$');
  }
}
