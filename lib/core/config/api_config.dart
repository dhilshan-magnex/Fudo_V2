import '../session/session_provider.dart';

class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://fudo.magnexsolutions.com/api/v1_5';

  static String url(String endpoint) {
    return urlForClient(
      endpoint,
      clientId: SessionProvider.currentClientId,
      locationId: SessionProvider.currentLocationId,
    );
  }

  static String urlForClient(
    String endpoint, {
    required String clientId,
    required String locationId,
  }) {
    final cleanEndpoint = endpoint.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    if (cleanEndpoint.isEmpty) {
      throw ArgumentError.value(endpoint, 'endpoint', 'cannot be empty');
    }
    final cleanClientId = clientId.trim();
    final cleanLocationId = locationId.trim();
    if (cleanClientId.isEmpty || cleanLocationId.isEmpty) {
      throw ArgumentError(
        'Client_ID and Location_ID are required for the API URL.',
      );
    }

    return '$baseUrl/$cleanEndpoint/${Uri.encodeComponent(cleanClientId)}/${Uri.encodeComponent(cleanLocationId)}';
  }
}
