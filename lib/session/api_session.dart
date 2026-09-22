class ApiSession {
  ApiSession._();

  static final ApiSession instance = ApiSession._();

  static const String defaultClientId = '940T0003';
  static const String defaultLocationId = '002';
  static const String defaultBaseUrl = 'http://fudo.magnexsolutions.com/api/v1_5';

  String? _clientId;
  String? _locationId;
  String? _baseUrl;


  // Getters
  String? get clientId => _clientId;
  String? get locationId => _locationId;
  String? get baseUrl => _baseUrl;

  bool get isActive =>
      _isNotBlank(_clientId) &&
      _isNotBlank(_locationId) &&
      _isNotBlank(_baseUrl);


  // Start API Session
  void start({
    required String clientId,
    required String locationId,
    required String baseUrl,
  }) {
    _clientId = clientId.trim();
    _locationId = locationId.trim();
    _baseUrl = _normalizeBaseUrl(baseUrl);
  }

  void startFromAppLicense(
    Map<String, dynamic> row, {
    String defaultLocationId = ApiSession.defaultLocationId,
    String defaultBaseUrl = ApiSession.defaultBaseUrl,
  }) {
    final clientId = _readString(row, 'Client_ID');
    final locationId = _readString(row, 'Location_ID') ?? defaultLocationId;
    final serverInfo = _readString(row, 'Server_Info');
    final activationServer = _readString(row, 'Activation_Server');
    final baseUrl = serverInfo ?? activationServer ?? defaultBaseUrl;

    if (!_isNotBlank(clientId)) {
      throw Exception('Client ID not found in App_License.');
    }

    start(
      clientId: clientId!,
      locationId: locationId,
      baseUrl: baseUrl,
    );
  }

  String urlFor(String endpoint) {
    ensureActive();

    return buildUrl(
      endpoint: endpoint,
      baseUrl: _baseUrl!,
      clientId: _clientId!,
      locationId: _locationId!,
    );
  }

  String bootstrapUrlFor(String endpoint) {
    return buildUrl(
      endpoint: endpoint,
      baseUrl: defaultBaseUrl,
      clientId: defaultClientId,
      locationId: defaultLocationId,
    );
  }

  String buildUrl({
    required String endpoint,
    required String baseUrl,
    required String clientId,
    required String locationId,
  }) {
    final cleanBaseUrl = _normalizeBaseUrl(baseUrl);
    final cleanEndpoint = endpoint.trim().replaceAll(RegExp(r'^/+|/+$'), '');

    return '$cleanBaseUrl/$cleanEndpoint/${clientId.trim()}/${locationId.trim()}';
  }


  // Validate API Session
  void ensureActive() {
    if (!isActive) {
      throw Exception(
        'API session has not been initialized.',
      );
    }
  }

  // Clear API Session
  void clear() {
    _clientId = null;
    _locationId = null;
    _baseUrl = null;
  }

  String _normalizeBaseUrl(String value) {
    return value.trim().replaceAll(RegExp(r'/+$'), '');
  }

  String? _readString(Map<String, dynamic> row, String columnName) {
    if (row.containsKey(columnName)) {
      return _blankToNull(row[columnName]?.toString());
    }

    final normalizedColumnName = _normalizeKey(columnName);

    for (final entry in row.entries) {
      if (_normalizeKey(entry.key) == normalizedColumnName) {
        return _blankToNull(entry.value?.toString());
      }
    }

    return null;
  }

  String _normalizeKey(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
  }

  String? _blankToNull(String? value) {
    final trimmedValue = value?.trim();
    if (trimmedValue == null || trimmedValue.isEmpty) return null;

    return trimmedValue;
  }

  bool _isNotBlank(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
