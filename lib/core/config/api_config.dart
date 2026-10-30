import '../session/session_provider.dart';

class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://fudo.magnexsolutions.com/api/v1_5';

  static String url(String endpoint) {
    final cleanEndpoint = endpoint.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    if (cleanEndpoint.isEmpty) {
      throw ArgumentError.value(endpoint, 'endpoint', 'cannot be empty');
    }

    return '$baseUrl/$cleanEndpoint/${SessionProvider.currentClientId}/${SessionProvider.currentLocationId}';
  }
}
