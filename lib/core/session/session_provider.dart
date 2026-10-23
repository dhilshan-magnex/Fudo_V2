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
  String? _locationId;
  String? _counterNo;

  String? get clientId => _clientId;
  String? get clientName => _clientName;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get clientType => _clientType;
  String? get groupCode => _groupCode;
  String? get locationId => _locationId;
  String? get counterNo => _counterNo;

  /// The client ID for the active application session.
  /// API services do not have a BuildContext, so they access the same provider
  /// instance through this getter when constructing request URLs.
  static String get currentClientId {
    final clientId = _current?._clientId?.trim();
    if (clientId == null || clientId.isEmpty) {
      throw StateError('No client ID is available in the current session.');
    }

    return clientId;
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

  bool get isLoggedIn => _userId != null;

  Future<void> setSession({
    required String clientId,
    String? clientName,
    required String userId,
    required String userName,
    String? clientType,
    String? groupCode,
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
    _locationId = null;
    _counterNo = null;

    notifyListeners();
  }
}
