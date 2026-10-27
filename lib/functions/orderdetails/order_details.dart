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
    var nextLineNo = 1;

    for (final item in order.items) {
      final lineNo = nextLineNo++;
      final note = item.note.trim();
      final lineValues = <String, Object?>{
        'Bill_No': int.parse(order.billNo!),
        'Line_No': lineNo,
        'Counter_No': SessionProvider.currentCounterNo,
        'Bill_Date': timestamp,
        'Tran_Time': timestamp,
        'KOT_No': kotNo,
        'Waiter_Code': order.waiterName,
        'Tran_Type': order.type,
        'Ref_No': order.refNo,
        'Ref_Type': _refType(order.type),
        'Menu_ID': item.id,
        'Tran_Description': item.name,
        'Tran_Qty': item.quantity,
        'Unit_Price': item.unitPrice,
        'Tran_Amount': item.subtotal,
        'Sales_Date': salesDate,
      };

      await transaction.insert('Tran_Detail', {
        ...lineValues,
        'Child_Line_No': 0,
      });

      if (note.isNotEmpty) {
        await transaction.insert('Tran_Detail', {
          ...lineValues,
          'Line_No': nextLineNo++,
          // Links this note row back to the item row for KOT printing.
          'Child_Line_No': lineNo,
          'Tran_Description': note,
          'Tran_Qty': 0,
          'Unit_Price': 0,
          'Tran_Amount': 0,
        });
      }
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

  String _refType(String type) => switch (type) {
    'Delivery' => 'DL',
    'Table' => 'TO',
    'Take Away' => 'TA',
    'Dine In' => 'QS',
    _ => 'OR',
  };
}
