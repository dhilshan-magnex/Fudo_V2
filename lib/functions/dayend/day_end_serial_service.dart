import 'package:fudo_v2/data/database/db_manager.dart';
import 'package:sqflite/sqflite.dart';

/// Creates and retrieves end-of-day serials in the local Fudo database.
class DayEndSerialService {
  Future<String?> addSalesDate({DateTime? currentDate}) async {
    final dateKey = _salesDateKey(currentDate ?? DateTime.now());
    final database = await DBManager.getDatabase(AppDatabase.fudo);

    return database.transaction((transaction) async {
      final headerCount = await _headerCount(transaction);

      if (headerCount == 0) {
        await transaction.insert('Day_End_Serial', {
          'Sales_Date': dateKey,
        });
        return dateKey;
      }

      return _latestSalesDate(transaction);
    });
  }

  Future<int> _headerCount(DatabaseExecutor database) async {
    final rows = await database.rawQuery(
      '''
        SELECT COUNT(*) AS header_count
        FROM Tran_Header
      ''',
    );
    return (rows.single['header_count'] as num).toInt();
  }

  Future<String?> _latestSalesDate(DatabaseExecutor database) async {
    final rows = await database.rawQuery(
      '''
        SELECT MAX(Sales_Date) AS sales_date
        FROM Day_End_Serial
        WHERE Sales_Date IS NOT NULL AND trim(Sales_Date) <> ''
      ''',
    );
    return rows.single['sales_date']?.toString();
  }

  String _salesDateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
