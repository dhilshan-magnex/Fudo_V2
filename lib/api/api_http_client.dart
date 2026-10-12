import 'package:http/http.dart' as http;

/// The application-owned client used by API services unless a test or caller
/// supplies a client explicitly. It can be closed during application teardown.
class ApiHttpClient {
  ApiHttpClient._();

  static http.Client? _client;

  static http.Client get instance => _client ??= http.Client();

  static void close() {
    _client?.close();
    _client = null;
  }
}
