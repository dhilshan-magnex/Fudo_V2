import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:fudo_v2/data/api/validuser_api.dart';
import 'package:fudo_v2/data/database/db_manager.dart';
import 'package:fudo_v2/data/server/users_api.dart';

class AuthService {
  AuthService({this._usersApi, ValidUserApi? validUserApi})
    : _validUserApi = validUserApi ?? ValidUserApi();

  final UsersApi? _usersApi;
  final ValidUserApi _validUserApi;

  Future<Map<String, dynamic>?> validateLogin(
    String clientType,
    String userId,
    String password, {
    String? clientId,
    String? locationId,
  }) async {
    if (DataSourceManager.getDataSource(clientType) == DataSource.api) {
      return _validUserApi.validateCredentials(
        userId: userId,
        password: password,
      );
    }
    final user = await DBManager.getUserForLogin(
      clientType,
      userId,
      usersApi: _usersApi,
    );

    if (user == null) {
      _logFailure(
        'No matching active user in the selected data source. '
        'Check User_Active.',
      );
      return null;
    }

    final storedPassword = (user['User_Pwd'] ?? '').toString();
    if (storedPassword.isEmpty) {
      _logFailure(
        'The user has no User_Pwd value. '
        'Check the selected data source.',
      );
      throw StateError(
        'The selected data source did not provide password data for login. '
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
