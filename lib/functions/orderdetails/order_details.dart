import 'package:sqflite/sqflite.dart';
import 'package:fudo_v2/core/session/session_provider.dart';
import 'package:fudo_v2/functions/orders/models/order.dart';

class KotService {

  /// Allocates a KOT number and saves every ordered item to `Tran_Detail`.
  Future<int> saveOrderLines({
    required DatabaseExecutor transaction,
    required Order order,
    required String salesDate,
  }) async {
    final kotNo = await _next(transaction, salesDate);
    final timestamp = order.createdAt.toIso8601String();

    for (var index = 0; index < order.items.length; index++) {
      final item = order.items[index];
      await transaction.insert('Tran_Detail', {
        'Bill_No': int.parse(order.billNo!),
        'Line_No': index + 1,
        'Counter_No': SessionProvider.currentCounterNo,
        'Bill_Date': timestamp,
        'Tran_Time': timestamp,
        'KOT_No': kotNo,
        'Waiter_Code': order.waiterName,
        'Tran_Ref': item.note,
        'Tran_Type': order.type,
        'Ref_No': order.refNo,
        'Ref_Type': _refType(order.type),
        'Menu_ID': item.id,
        'Tran_Description': item.name,
        'Tran_Qty': item.quantity,
        'Unit_Price': item.unitPrice,
        'Tran_Amount': item.subtotal,
        'Sales_Date': salesDate,
      });
    }
    return kotNo;
  }

  Future<int> _next(DatabaseExecutor transaction, String salesDate) async {
    return (await _lastExistingKotNo(transaction, salesDate)) + 1;
  }

  Future<int> _lastExistingKotNo(
    DatabaseExecutor database,
    String salesDate,
  ) async {
    final rows = await database.rawQuery(
      '''
        SELECT COALESCE(MAX(KOT_No), 0) AS last_kot_no
        FROM Tran_Detail
        WHERE Bill_Date LIKE ?
      ''',
      ['$salesDate%'],
    );
    return (rows.single['last_kot_no'] as num?)?.toInt() ?? 0;
  }

  String _salesDateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _refType(String type) => switch (type) {
    'Delivery' => 'DL',
    'Table' => 'TO',
    'Take Away' => 'TA',
    'Dine In' => 'QS',
    _ => 'OR',
  };
}
