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
    final kotNo = await _lastExistingKotNo(transaction, salesDate) + 1;
    final tranTime = _timeOnly(order.createdAt);
    final billDate = _dateOnly(order.createdAt);
    final menuCategories = <String, Map<String, Object?>>{};
    var nextLineNo = await _nextLineNo(
      transaction,
      int.parse(order.billNo!),
      SessionProvider.currentCounterNo,
    );

    for (final item in order.items) {
      final lineNo = nextLineNo++;
      final note = item.note.trim();
      final category = await _menuCategory(
        transaction,
        item.id,
        menuCategories,
      );
      final lineValues = <String, Object?>{
        'Bill_No': int.parse(order.billNo!),
        'Line_No': lineNo,
        'Counter_No': SessionProvider.currentCounterNo,
        'User_Id': SessionProvider.currentUserId,
        'Bill_Date': billDate,
        'Bill_Status': 0,
        'Tran_Time': tranTime,
        'KOT_No': kotNo,
        'Waiter_Code': SessionProvider.currentGroupName,
        'Tran_Type': _tranType(order.type),
        'Ref_No': order.refNo,
        'Ref_Type': _refType(order.type),
        'Menu_ID': item.id,
        'Tran_Description': item.name,
        'Cat_Code': category?['Cat_Code'],
        'Cat_Lvl2_Code': category?['Cat_Lv2_Code'],
        'Cat_Type': category?['Cat_Type'],
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

  Future<Map<String, Object?>?> _menuCategory(
    DatabaseExecutor transaction,
    String menuId,
    Map<String, Map<String, Object?>> cache,
  ) async {
    final cachedCategory = cache[menuId];
    if (cachedCategory != null) return cachedCategory;

    final rows = await transaction.rawQuery(
      '''
        SELECT
          menu.Cat_Code,
          menu.Cat_Lv2_Code,
          category.Cat_Type
        FROM Menu_Items AS menu
        LEFT JOIN Category_Lvl1 AS category
          ON category.Cat_Code = menu.Cat_Code
        WHERE menu.Menu_ID = ?
        LIMIT 1
      ''',
      [menuId],
    );
    if (rows.isEmpty) return null;

    final category = Map<String, Object?>.from(rows.single);
    cache[menuId] = category;
    return category;
  }

  Future<int> _nextLineNo(
    DatabaseExecutor transaction,
    int billNo,
    String counterNo,
  ) async {
    final rows = await transaction.rawQuery(
      '''
        SELECT COALESCE(MAX(Line_No), 0) + 1 AS next_line_no
        FROM Tran_Detail
        WHERE Bill_No = ? AND Counter_No = ?
      ''',
      [billNo, counterNo],
    );
    return (rows.single['next_line_no'] as num).toInt();
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

  String _tranType(String type) => switch (type.trim().toLowerCase()) {
    'void' || 'voided' => 'TV',
    'comment' || 'comments' => 'TM',
    'cancel' || 'cancelled' || 'canceled' => 'XX',
    'return' || 'returned' => 'TR',
    _ => 'TS',
  };

  /// Stores database bill dates without a time component.
  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _timeOnly(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}
