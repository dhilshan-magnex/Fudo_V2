import 'package:flutter/foundation.dart';

class SessionProvider extends ChangeNotifier {
  static SessionProvider? _current;

  SessionProvider() {
    _current = this;
  }

  String? _clientId;
  String? _clientName;
  String? _userId;
  String? _userName;
  String? _clientType;
  String? _groupCode;

  String? get clientId => _clientId;
  String? get clientName => _clientName;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get clientType => _clientType;
  String? get groupCode => _groupCode;

  /// The client ID for the active application session.
  ///
  /// API services do not have a BuildContext, so they access the same provider
  /// instance through this getter when constructing request URLs.
  static String get currentClientId {
    final clientId = _current?._clientId?.trim();
    if (clientId == null || clientId.isEmpty) {
      throw StateError('No client ID is available in the current session.');
    }

    return clientId;
  }

  bool get isLoggedIn => _userId != null;

  void setSession({
    required String clientId,
    String? clientName,
    required String userId,
    required String userName,
    String? clientType,
    String? groupCode,
  }) {
    _clientId = clientId;
    _clientName = clientName;
    _userId = userId;
    _userName = userName;
    _clientType = clientType;
    _groupCode = groupCode;

    notifyListeners();
  }

  void logout() {
    _clientId = null;
    _clientName = null;
    _userId = null;
    _userName = null;
    _clientType = null;
    _groupCode = null;

    notifyListeners();
  }
}
