import '../models/order.dart';
import 'order_database.dart';
import '../../orderdetails/order_details.dart';
import '../../dayend/day_end_serial_service.dart';
import 'package:fudo_v2/core/session/session_provider.dart';

class OrderRepository {
  OrderRepository(this._database, this._kotService);
  final OrderDatabase _database;
  final KotService _kotService;
  final DayEndSerialService _dayEndSerialService = DayEndSerialService();

  /// Creates a readable reference appropriate to the order type.
  /// Table references intentionally use the physical table number.
  Future<String> createRefNo({
    required String type,
    String? tableNumber,
  }) async {
    if (type == 'Table' &&
        tableNumber != null &&
        tableNumber.trim().isNotEmpty) {
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
    if (order.billNo == null) {
      throw ArgumentError('Bill number is required before saving Tran_Header.');
    }
    final customerCode = _customerCode();
    final db = await _database.database;
    await db.insert('Tran_Header', {
      'Bill_No': int.parse(order.billNo!),
      'Ref_No': order.refNo,
      'Ref_Type': _refType(order.type),
      'Counter_No': SessionProvider.currentCounterNo,
      'Customer_Code': customerCode,
      'Customer_Name': order.customerName,
      'PAX': order.pax ?? 1,
      'Taxable': 0,
      'Header_Ref1': order.orderNote,
      'Bill_Date': order.createdAt.toIso8601String(),
      'Sales_Date': order.createdAt.toIso8601String(),
      'Bill_Value': order.subtotal,
      'Print_Count': 0,
      'Tax_Total': 0,
      'Service_Charge': 0,
      'Recall_Bill_Flag': order.status == OrderStatus.voided ? 1 : 0,
    });
  }

  Future<Order> createOrder(Order order) async {
    final customerCode = _customerCode();
    final salesDate = await _dayEndSerialService.addSalesDate(
      currentDate: order.createdAt,
    );
    if (salesDate == null) {
      throw StateError(
        'Cannot place an order: no sales date exists in Day_End_Serial.',
      );
    }
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
        'Counter_No': SessionProvider.currentCounterNo,
        'Customer_Code': customerCode,
        'Customer_Name': saved.customerName,
        'PAX': saved.pax ?? 1,
        'Taxable': 0,
        'Header_Ref': null,
        'Header_Ref1': saved.orderNote,
        'Bill_Date': saved.createdAt.toIso8601String(),
        'Sales_Date': salesDate,
        'Bill_Value': saved.subtotal,
        'Print_Count': 0,
        'Tax_Total': 0,
        'Service_Charge': 0,
        'Recall_Bill_Flag': 0,
        'SC_Included': 0,
      });
      await _kotService.saveOrderLines(
        transaction: tx,
        order: saved,
        salesDate: salesDate,
      );
      return saved;
    });
  }

  /// Saves additional items to an existing bill and updates its total.
  Future<void> addItemsToOrder(Order order) async {
    if (order.billNo == null) {
      throw ArgumentError('Bill number is required before adding items.');
    }
    if (order.items.isEmpty) {
      throw ArgumentError('At least one item must be added to an order.');
    }

    final db = await _database.database;
    await db.transaction((tx) async {
      final headerRows = await tx.query(
        'Tran_Header',
        columns: const ['Sales_Date'],
        where: 'Bill_No = ?',
        whereArgs: [int.parse(order.billNo!)],
        limit: 1,
      );
      if (headerRows.isEmpty) {
        throw StateError('Bill ${order.billNo} was not found.');
      }

      final salesDate = headerRows.single['Sales_Date'] as String?;
      if (salesDate == null || salesDate.isEmpty) {
        throw StateError('Bill ${order.billNo} has no sales date.');
      }

      await _kotService.saveOrderLines(
        transaction: tx,
        order: order,
        salesDate: salesDate,
      );
      await tx.rawUpdate(
        '''
          UPDATE Tran_Header
          SET Bill_Value = COALESCE(Bill_Value, 0) + ?
          WHERE Bill_No = ?
        ''',
        [order.subtotal, int.parse(order.billNo!)],
      );
    });
  }

  Future<void> updateOrderItemQuantity({
    required String billNo,
    required String menuId,
    required int quantity,
    required String reason,
  }) async {
    if (quantity < 1) {
      throw ArgumentError.value(quantity, 'quantity', 'must be at least 1');
    }

    final db = await _database.database;
    await db.transaction((tx) async {
      final detailRows = await tx.query(
        'Tran_Detail',
        where: 'Bill_No = ? AND Menu_ID = ? AND Child_Line_No = 0',
        whereArgs: [int.parse(billNo), menuId],
        orderBy: 'Line_No ASC',
      );
      if (detailRows.isEmpty) {
        throw StateError('Item $menuId was not found on bill $billNo.');
      }

      // A void is kept as its own transaction line with a negative amount.
      // This preserves the original sale and makes reductions auditable.
      final currentQuantity = detailRows.fold<int>(
        0,
        (total, row) {
          final lineQuantity = (row['Tran_Qty'] as num).toInt().abs();
          return row['Tran_Type'] == 'TV'
              ? total - lineQuantity
              : total + lineQuantity;
        },
      );
      final saleLine = detailRows.lastWhere(
        (row) => row['Tran_Type'] != 'TV',
        orElse: () => throw StateError(
          'No sale line was found for item $menuId on bill $billNo.',
        ),
      );

      if (quantity < currentQuantity) {
        final voidQuantity = currentQuantity - quantity;
        final nextLineRows = await tx.rawQuery(
          '''
            SELECT COALESCE(MAX(Line_No), 0) + 1 AS next_line_no
            FROM Tran_Detail
            WHERE Bill_No = ? AND Counter_No = ?
          ''',
          [int.parse(billNo), SessionProvider.currentCounterNo],
        );
        final voidLine = Map<String, Object?>.from(saleLine)
          ..['Line_No'] = (nextLineRows.single['next_line_no'] as num).toInt()
          ..['Child_Line_No'] = 0
          // Keep the order reference type (for example, QS for Dine In).
          // The transaction type, rather than the reference type, marks this
          // detail row as a void.
          ..['Tran_Type'] = 'TV'
          // Store the number of voided items as a positive quantity. The
          // negative amount applies the reduction to the bill total.
          ..['Tran_Qty'] = voidQuantity
          ..['Tran_Amount'] =
              -((saleLine['Unit_Price'] as num).toDouble() * voidQuantity)
          ..['Tran_Ref'] = reason
          ..['Bill_Date'] = DateTime.now().toIso8601String()
          ..['Tran_Time'] = DateTime.now().toIso8601String();

        // `Bill_No` is part of the source line's key and is NOT NULL. It
        // must remain on the void row. Do not remove columns merely because
        // they are primary-key columns: this database defines `Bill_No` that
        // way, rather than using an auto-generated detail-row id.
        voidLine.remove('id');
        await tx.insert('Tran_Detail', voidLine);
      } else if (quantity > currentQuantity) {
        final additionalQuantity = quantity - currentQuantity;
        final saleQuantity = (saleLine['Tran_Qty'] as num).toInt();
        final unitPrice = (saleLine['Unit_Price'] as num).toDouble();
        await tx.update(
          'Tran_Detail',
          {
            'Tran_Qty': saleQuantity + additionalQuantity,
            'Tran_Amount': unitPrice * (saleQuantity + additionalQuantity),
            'Tran_Ref': reason,
          },
          where: 'Bill_No = ? AND Line_No = ?',
          whereArgs: [int.parse(billNo), saleLine['Line_No']],
        );
      }

      await tx.rawUpdate(
        '''
          UPDATE Tran_Header
          SET Bill_Value = (
            SELECT COALESCE(SUM(Tran_Amount), 0)
            FROM Tran_Detail
            WHERE Bill_No = Tran_Header.Bill_No AND Child_Line_No = 0
          )
          WHERE Bill_No = ?
        ''',
        [int.parse(billNo)],
      );
    });
  }

  Future<List<Order>> getAll() async {
    final db = await _database.database;
    final rows = await db.query('Tran_Header', orderBy: 'Bill_No DESC');
    return rows.map(_fromHeader).toList();
  }

  Future<Order?> getByRefNo(String refNo) async {
    final db = await _database.database;
    final rows = await db.query(
      'Tran_Header',
      where: 'Ref_No = ?',
      whereArgs: [refNo],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromHeader(rows.single);
  }

  Future<void> delete(String refNo) async {
    final db = await _database.database;
    await db.delete('Tran_Header', where: 'Ref_No = ?', whereArgs: [refNo]);
  }

  Future<String> assignNextBillNo(String refNo) async {
    final order = await getByRefNo(refNo);
    if (order == null) throw StateError('Order $refNo was not found.');
    if (order.billNo != null) return order.billNo!;
    throw StateError('Legacy Tran_Header order $refNo has no Bill_No.');
  }

  String _refType(String type) => switch (type) {
    'Delivery' => 'DL',
    'Table' => 'TO',
    'Take Away' => 'TA',
    'Dine In' => 'QS',
    _ => 'OR',
  };

  String _orderType(String refType) => switch (refType) {
    'DL' => 'Delivery',
    'TB' => 'Table',
    'TA' => 'Take Away',
    'QS' => 'Dine In',
    _ => 'Order',
  };

  /// Customer codes are scoped to the configured outlet location.
  String _customerCode() => 'C${SessionProvider.currentLocationId}1';

  Order _fromHeader(Map<String, Object?> row) => Order(
    refNo: row['Ref_No'] as String? ?? 'LEGACY-${row['Bill_No']}',
    billNo: (row['Bill_No'] as num).toInt().toString(),
    type: _orderType(row['Ref_Type'] as String? ?? ''),
    items: const [],
    status: (row['Recall_Bill_Flag'] as int? ?? 0) == 1
        ? OrderStatus.voided
        : OrderStatus.paid,
    createdAt:
        DateTime.tryParse(row['Bill_Date'] as String? ?? '') ?? DateTime.now(),
    posId: row['Counter_No'] as String? ?? '',
    tableNumber: row['Header_Ref'] as String?,
    customerName: row['Customer_Name'] as String?,
    orderNote: row['Header_Ref1'] as String?,
    pax: row['PAX'] as int?,
  );
}
