import 'package:bcrypt/bcrypt.dart';
import '../database/db_manager.dart';

class AuthService {
  Future<Map<String, dynamic>?> validateLogin(
    String clientId,
    String userId,
    String password,
  ) async {
    final user = await DBManager.getUserForLogin(clientId, userId);

    if (user == null) return null;

    final storedPassword = (user['User_Pwd'] ?? '').toString();

    bool passwordValid;

    if (_isBcryptHash(storedPassword)) {
      passwordValid = BCrypt.checkpw(password, storedPassword);
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
