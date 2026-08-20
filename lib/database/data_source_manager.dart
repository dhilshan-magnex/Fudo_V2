import 'data_source.dart';

class DataSourceManager {
  static DataSource getDataSource(String clientId) {
    if (clientId == '001') {
      return DataSource.sqlite;
    }

    return DataSource.api;
  }
}