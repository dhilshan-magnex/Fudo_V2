class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://fudo.magnexsolutions.com/api/v1_5';
  static const String clientId = '940T0003';
  static const String locationId = '002';

  static String url(String endpoint) {
    final cleanEndpoint = endpoint.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    return '$baseUrl/$cleanEndpoint/$clientId/$locationId';
  }
}
