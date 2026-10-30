import 'package:flutter/foundation.dart';
import 'package:fudo_v2/data/database/db_manager.dart';

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
  String? _groupName;
  String? _locationId;
  String? _counterNo;

  String? get clientId => _clientId;
  String? get clientName => _clientName;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get clientType => _clientType;
  String? get groupCode => _groupCode;
  String? get groupName => _groupName;
  String? get locationId => _locationId;
  String? get counterNo => _counterNo;

  static String get currentClientId {
    final clientId = _current?._clientId?.trim();
    if (clientId == null || clientId.isEmpty) {
      throw StateError('No client ID is available in the current session.');
    }

    return clientId;
  }

  /// The authenticated user who is operating the current POS session.
  static String get currentUserId {
    final userId = _current?._userId?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('No user ID is available in the current session.');
    }
    return userId;
  }

  static String get currentLocationId {
    final locationId = _current?._locationId?.trim();
    if (locationId == null || locationId.isEmpty) {
      throw StateError('No location ID is available in the current session.');
    }
    return locationId;
  }

  static String get currentCounterNo {
    final counterNo = _current?._counterNo?.trim();
    if (counterNo == null || counterNo.isEmpty) {
      throw StateError('No counter number is available in the current session.');
    }
    return counterNo;
  }

  static String get currentClientName {
    final clientName = _current?._clientName?.trim();
    if (clientName == null || clientName.isEmpty) {
      throw StateError('No client name is available in the current session.');
    }
    return clientName;
  }

  static String get currentGroupName {
    final groupName = _current?._groupName?.trim();
    if (groupName == null || groupName.isEmpty) {
      throw StateError('No group name is available in the current session.');
    }
    return groupName;
  }

  static String get currentUserName {
    final userName = _current?._userName?.trim();
    if (userName == null || userName.isEmpty) {
      throw StateError('No user name is available in the current session.');
    }
    return userName;
  }

  bool get isLoggedIn => _userId != null;

  Future<void> setSession({
    required String clientId,
    String? clientName,
    required String userId,
    required String userName,
    String? clientType,
    String? groupCode,
    String? groupName,
  }) async {
    final counterInfo = await DBManager.getCounterInfo();
    final locationId = counterInfo?['Location_ID']?.toString().trim();
    final counterNo = counterInfo?['Counter_No']?.toString().trim();
    if (locationId == null || locationId.isEmpty) {
      throw StateError('Location_ID is not configured for counter 01.');
    }
    if (counterNo == null || counterNo.isEmpty) {
      throw StateError('Counter_No is not configured in Counter_Info.');
    }

    _clientId = clientId;
    _clientName = clientName;
    _userId = userId;
    _userName = userName;
    _clientType = clientType;
    _groupCode = groupCode;
    _groupName = groupName;
    _locationId = locationId;
    _counterNo = counterNo;

    notifyListeners();
  }

  void logout() {
    _clientId = null;
    _clientName = null;
    _userId = null;
    _userName = null;
    _clientType = null;
    _groupCode = null;
    _groupName = null;
    _locationId = null;
    _counterNo = null;

    notifyListeners();
  }
}
