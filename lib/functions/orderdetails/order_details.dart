import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fudo_v2/core/session/session_provider.dart';
import 'package:fudo_v2/data/database/db_manager.dart';
import 'package:fudo_v2/functions/orders/models/order.dart';


class KotService extends ChangeNotifier {
  static const _sequenceTable = 'KOT_Number_Sequence';

  int? _lastGenerated;
  Object? _error;
  bool _isGenerating = false;

  int? get lastGenerated => _lastGenerated;
  Object? get error => _error;
  bool get isGenerating => _isGenerating;


  Future<int> generate({DateTime? salesDate}) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final dateKey = _salesDateKey(salesDate ?? DateTime.now());
      final database = await DBManager.getDatabase(AppDatabase.fudo);
      final kotNo = await database.transaction<int>((transaction) async {
        return _next(transaction, dateKey);
      });

      _lastGenerated = kotNo;
      return kotNo;
    } catch (error) {
      _error = error;
      rethrow;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Allocates a KOT number and saves every ordered item to `Tran_Detail`.
  Future<int> saveOrderLines({
    required DatabaseExecutor transaction,
    required Order order,
  }) async {
    final salesDate = _salesDateKey(order.createdAt);
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
    await transaction.execute('''
      CREATE TABLE IF NOT EXISTS $_sequenceTable (
        Sales_Date TEXT NOT NULL PRIMARY KEY,
        Last_KOT_No INTEGER NOT NULL
      )
    ''');

    final sequence = await transaction.query(
      _sequenceTable,
      columns: const ['Last_KOT_No'],
      where: 'Sales_Date = ?',
      whereArgs: [salesDate],
      limit: 1,
    );
    final previous = sequence.isEmpty
        ? await _lastExistingKotNo(transaction, salesDate)
        : (sequence.single['Last_KOT_No'] as num).toInt();
    final next = previous + 1;

    if (sequence.isEmpty) {
      await transaction.insert(_sequenceTable, {
        'Sales_Date': salesDate,
        'Last_KOT_No': next,
      });
    } else {
      await transaction.update(
        _sequenceTable,
        {'Last_KOT_No': next},
        where: 'Sales_Date = ?',
        whereArgs: [salesDate],
      );
    }
    return next;
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
    'Dine In' => 'DI',
    _ => 'OR',
  };
}
