import 'package:http/http.dart' as http;

class ApiHttpClient {
  ApiHttpClient._();

  static http.Client? _client;

  static http.Client get instance => _client ??= http.Client();

  static void close() {
    _client?.close();
    _client = null;
  }
}
