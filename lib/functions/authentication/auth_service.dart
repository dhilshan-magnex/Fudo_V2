import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:fudo_v2/data/database/db_manager.dart';

class AuthService {
  Future<Map<String, dynamic>?> validateLogin(
    String clientType,
    String userId,
    String password,
  ) async {
    final user = await DBManager.getUserForLogin(clientType, userId);

    if (user == null) {
      _logFailure(
        'No matching active user in the local User_File. '
        'Check user synchronization and User_Active.',
      );
      return null;
    }

    final storedPassword = (user['User_Pwd'] ?? '').toString();
    if (storedPassword.isEmpty) {
      _logFailure(
        'The synced user has no User_Pwd value. '
        'Check the users API response and sync mapping.',
      );
      throw StateError(
        'The users API did not provide password data for local login. '
        'Configure backend authentication before signing in.',
      );
    }

    final passwordValid = _isBcryptHash(storedPassword)
        ? _checkBcryptPassword(password, storedPassword)
        : password == storedPassword;

    if (!passwordValid) {
      _logFailure(
        _isBcryptHash(storedPassword)
            ? 'Bcrypt password verification failed.'
            : 'Stored password is not a recognized bcrypt hash and the exact '
                  'password comparison failed. Check the backend password format.',
      );
      return null;
    }

    return user;
  }

  void _logFailure(String reason) {
    if (kDebugMode) debugPrint('Login diagnostic: $reason');
  }

  bool _isBcryptHash(String value) {
    return value.startsWith(r'$2a$') ||
        value.startsWith(r'$2b$') ||
        value.startsWith(r'$2y$');
  }

  bool _checkBcryptPassword(String password, String storedHash) {
    try {
      return BCrypt.checkpw(password, storedHash);
    } on FormatException {
      _logFailure('The stored bcrypt hash has an invalid format.');
      return false;
    } catch (_) {
      _logFailure('The stored bcrypt hash could not be verified.');
      return false;
    }
  }
}
