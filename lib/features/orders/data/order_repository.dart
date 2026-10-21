import '../models/order.dart';
import 'order_database.dart';

class OrderRepository {
  OrderRepository(this._database);
  final OrderDatabase _database;

  /// Creates a readable reference appropriate to the order type.
  /// Table references intentionally use the physical table number.
  Future<String> createRefNo({
    required String type,
    String? tableNumber,
  }) async {
    if (type == 'Table' && tableNumber != null && tableNumber.trim().isNotEmpty) {
      return tableNumber.trim();
    }

    final prefix = _refType(type);
    final db = await _database.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(MAX(CAST(SUBSTR(Ref_No, 3) AS INTEGER)), 0) + 1
      AS next_ref_no
      FROM Tran_Header
      WHERE Ref_Type = ? AND Ref_No GLOB ?
      ''',
      [prefix, '$prefix[0-9]*'],
    );
    final sequence = (result.single['next_ref_no'] as num).toInt();
    return '$prefix${sequence.toString().padLeft(3, '0')}';
  }

  Future<String> nextBillNo() async {
    final db = await _database.database;
    return db.transaction((tx) async {
      final result = await tx.rawQuery(
        'SELECT COALESCE(MAX(Bill_No), 0) + 1 AS next_bill_no FROM Tran_Header',
      );
      return (result.single['next_bill_no'] as num).toInt().toString();
    });
  }
  Future<void> save(Order order) async {
    if (order.billNo == null) throw ArgumentError('Bill number is required before saving Tran_Header.');
    final db = await _database.database;
    await db.insert('Tran_Header', {
      'Bill_No': int.parse(order.billNo!),
      'Ref_No': order.refNo,
      'Ref_Type': _refType(order.type),
      'Counter_No': order.posId,
      'Customer_Name': order.customerName,
      'PAX': order.pax,
      'Header_Ref': order.tableNumber,
      'Header_Ref1': order.orderNote,
      'Bill_Date': order.createdAt.toIso8601String(),
      'Sales_Date': order.createdAt.toIso8601String(),
      'Bill_Value': order.subtotal,
      'Recall_Bill_Flag': order.status == OrderStatus.voided ? 1 : 0,
    });
  }
  Future<Order> createOrder(Order order) async {
    final db = await _database.database;
    return db.transaction((tx) async {
      final result = await tx.rawQuery(
        'SELECT COALESCE(MAX(Bill_No), 0) + 1 AS next_bill_no FROM Tran_Header',
      );
      final billNo = (result.single['next_bill_no'] as num).toInt().toString();
      final saved = order.copyWith(billNo: billNo);
      await tx.insert('Tran_Header', {
        'Bill_No': int.parse(billNo),
        'Ref_No': saved.refNo,
        'Ref_Type': _refType(saved.type),
        'Counter_No': saved.posId,
        'Customer_Name': saved.customerName,
        'PAX': saved.pax,
        'Header_Ref': saved.tableNumber,
        'Header_Ref1': saved.orderNote,
        'Bill_Date': saved.createdAt.toIso8601String(),
        'Sales_Date': saved.createdAt.toIso8601String(),
        'Bill_Value': saved.subtotal,
        'Recall_Bill_Flag': 0,
      });
      return saved;
    });
  }
  Future<List<Order>> getAll() async { final db = await _database.database; final rows = await db.query('Tran_Header', orderBy: 'Bill_No DESC'); return rows.map(_fromHeader).toList(); }
  Future<Order?> getByRefNo(String refNo) async { final db = await _database.database; final rows = await db.query('Tran_Header', where: 'Ref_No = ?', whereArgs: [refNo], limit: 1); return rows.isEmpty ? null : _fromHeader(rows.single); }
  Future<void> delete(String refNo) async { final db = await _database.database; await db.delete('Tran_Header', where: 'Ref_No = ?', whereArgs: [refNo]); }
  Future<String> assignNextBillNo(String refNo) async {
    final order = await getByRefNo(refNo);
      if (order == null) throw StateError('Order $refNo was not found.');
      if (order.billNo != null) return order.billNo!;
    throw StateError('Legacy Tran_Header order $refNo has no Bill_No.');
  }
  String _refType(String type) => switch (type) {
    'Delivery' => 'DL',
    'Table' => 'TB',
    'Take Away' => 'TA',
    'Dine In' => 'DI',
    _ => 'OR',
  };

  String _orderType(String refType) => switch (refType) {
    'DL' => 'Delivery',
    'TB' => 'Table',
    'TA' => 'Take Away',
    'DI' => 'Dine In',
    _ => 'Order',
  };

  Order _fromHeader(Map<String, Object?> row) => Order(refNo: row['Ref_No'] as String? ?? 'LEGACY-${row['Bill_No']}', billNo: (row['Bill_No'] as num).toInt().toString(), type: _orderType(row['Ref_Type'] as String? ?? ''), items: const [], status: (row['Recall_Bill_Flag'] as int? ?? 0) == 1 ? OrderStatus.voided : OrderStatus.paid, createdAt: DateTime.tryParse(row['Bill_Date'] as String? ?? '') ?? DateTime.now(), posId: row['Counter_No'] as String? ?? '', tableNumber: row['Header_Ref'] as String?, customerName: row['Customer_Name'] as String?, orderNote: row['Header_Ref1'] as String?, pax: row['PAX'] as int?);
}
