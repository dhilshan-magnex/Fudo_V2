import 'package:bcrypt/bcrypt.dart';
import 'package:fudo_v2/data/database/db_manager.dart';

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

    // Plaintext credential records are intentionally not accepted. Migrate
    // legacy users to bcrypt hashes before enabling their accounts.
    if (!_isBcryptHash(storedPassword)) return null;
    passwordValid = BCrypt.checkpw(password, storedPassword);

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
