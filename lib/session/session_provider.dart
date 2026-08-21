import 'package:flutter/foundation.dart';

class SessionProvider extends ChangeNotifier {
  String? _clientId;
  String? _clientName;
  String? _userId;
  String? _userName;
  String? _clientType;

  String? get clientId => _clientId;
  String? get clientName => _clientName;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get clientType => _clientType;

  bool get isLoggedIn => _userId != null;

  void setSession({
    required String clientId,
    String? clientName,
    required String userId,
    required String userName,
    String? clientType,
  }) {
    _clientId = clientId;
    _clientName = clientName;
    _userId = userId;
    _userName = userName;
    _clientType = clientType;

    notifyListeners();
  }

  void logout() {
    _clientId = null;
    _clientName = null;
    _userId = null;
    _userName = null;
    _clientType = null;

    notifyListeners();
  }
}