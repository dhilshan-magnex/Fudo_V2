import 'package:fudo_v2/core/session/session_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../dayend/day_end_serial_service.dart';
import '../../orderdetails/order_details.dart';
import '../models/order.dart';
import 'order_database.dart';

const _headerTable = 'Tran_Header';
const _detailTable = 'Tran_Detail';
const _voidTransactionType = 'TV';

class OrderRepository {
  OrderRepository(this._database, this._kotService);
  final OrderDatabase _database;
  final KotService _kotService;
  final _dayEndSerialService = DayEndSerialService();

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
    return db.transaction(_nextBillNo);
  }

  Future<void> save(Order order) async {
    if (order.billNo == null) {
      throw ArgumentError('Bill number is required before saving Tran_Header.');
    }
    final customerCode = _customerCode();
    final db = await _database.database;
    await db.insert(
      _headerTable,
      _headerValues(
        order,
        customerCode: customerCode,
        salesDate: order.createdAt.toIso8601String(),
        isVoided: order.status == OrderStatus.voided,
      ),
    );
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
      final billNo = await _nextBillNo(tx);
      final saved = order.copyWith(billNo: billNo);
      await tx.insert(
        _headerTable,
        _headerValues(
          saved,
          customerCode: customerCode,
          salesDate: salesDate,
          includeServiceChargeFlag: true,
        ),
      );
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
      await tx.update(
        _detailTable,
        {'Bill_Status': 0},
        where: 'Bill_No = ?',
        whereArgs: [int.parse(order.billNo!)],
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

  /// Marks every detail row for a bill as open for additional items.
  Future<void> markBillOpenForAddItems(String billNo) async {
    final db = await _database.database;
    final updatedRows = await db.update(
      _detailTable,
      {'Bill_Status': 1},
      where: 'Bill_No = ?',
      whereArgs: [int.parse(billNo)],
    );
    if (updatedRows == 0) {
      throw StateError('No detail rows found for bill $billNo.');
    }
  }

  Future<void> markBillAddItemsConfirmed(String billNo) async {
    final db = await _database.database;
    await db.update(
      _detailTable,
      {'Bill_Status': 0},
      where: 'Bill_No = ?',
      whereArgs: [int.parse(billNo)],
    );
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
        _detailTable,
        where: 'Bill_No = ? AND Menu_ID = ? AND Child_Line_No = 0',
        whereArgs: [int.parse(billNo), menuId],
        orderBy: 'Line_No ASC',
      );
      if (detailRows.isEmpty) {
        throw StateError('Item $menuId was not found on bill $billNo.');
      }


      final saleLine = detailRows.lastWhere(
        (row) => row['Tran_Type'] != _voidTransactionType,
        orElse: () => throw StateError(
          'No sale line was found for item $menuId on bill $billNo.',
        ),
      );
      // The sale rows store the current ordered quantity. TV rows are an
      // audit trail, so they must not reduce this value again.
      final currentQuantity = detailRows
          .where((row) => row['Tran_Type'] != _voidTransactionType)
          .fold<int>(
            0,
            (total, row) => total + (row['Tran_Qty'] as num).toInt(),
          );

      if (quantity < currentQuantity) {
        final voidQuantity = currentQuantity - quantity;
        final saleQuantity = (saleLine['Tran_Qty'] as num).toInt();
        final remainingSaleQuantity = saleQuantity - voidQuantity;
        final unitPrice = (saleLine['Unit_Price'] as num).toDouble();
        if (remainingSaleQuantity < 1) {
          throw StateError('The item quantity cannot be reduced below 1.');
        }

        await tx.update(
          _detailTable,
          {
            'Tran_Qty': remainingSaleQuantity,
            'Tran_Amount': unitPrice * remainingSaleQuantity,
          },
          where: 'Bill_No = ? AND Line_No = ?',
          whereArgs: [int.parse(billNo), saleLine['Line_No']],
        );

        final nextLineRows = await tx.rawQuery(
          '''
            SELECT COALESCE(MAX(Line_No), 0) + 1 AS next_line_no
            FROM $_detailTable
            WHERE Bill_No = ? AND Counter_No = ?
          ''',
          [int.parse(billNo), SessionProvider.currentCounterNo],
        );
        final now = DateTime.now();
        final voidLine = Map<String, Object?>.from(saleLine)
          ..['Line_No'] = (nextLineRows.single['next_line_no'] as num).toInt()
          ..['Child_Line_No'] = 0
          ..['Tran_Type'] = _voidTransactionType
          ..['Tran_Qty'] = voidQuantity
          ..['Unit_Price'] = 0
          ..['Tran_Amount'] = 0
          ..['Tran_Ref'] = reason
          ..['User_Id'] = SessionProvider.currentUserId
          ..['Bill_Date'] = _dateOnly(now)
          ..['Tran_Time'] = _timeOnly(now)
          ..['Bill_Status'] = 0
          ..remove('id');
        await tx.insert(_detailTable, voidLine);
      } else if (quantity > currentQuantity) {
        final additionalQuantity = quantity - currentQuantity;
        final saleQuantity = (saleLine['Tran_Qty'] as num).toInt();
        final unitPrice = (saleLine['Unit_Price'] as num).toDouble();
        await tx.update(
          _detailTable,
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
            SELECT COALESCE(SUM(
              CASE
                WHEN Tran_Type = 'TV' THEN 0
                ELSE Tran_Amount
              END
            ), 0)
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

  /// Records the logged-in cashier on each transaction detail at checkout.
  Future<void> recordCheckout(String billNo) async {
    final db = await _database.database;
    final updatedRows = await db.update(
      _detailTable,
      {'Cashier_Code': SessionProvider.currentUserId},
      where: 'Bill_No = ?',
      whereArgs: [int.parse(billNo)],
    );
    if (updatedRows == 0) {
      throw StateError('No transaction details were found for bill $billNo.');
    }
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
    'TO' => 'Table',
    'TA' => 'Take Away',
    'QS' => 'Dine In',
    _ => 'Order',
  };

  /// Customer codes are scoped to the configured outlet location.
  String _customerCode() => 'C${SessionProvider.currentLocationId}1';

  Future<String> _nextBillNo(DatabaseExecutor database) async {
    final result = await database.rawQuery(
      'SELECT COALESCE(MAX(Bill_No), 0) + 1 AS next_bill_no FROM $_headerTable',
    );
    return (result.single['next_bill_no'] as num).toInt().toString();
  }

  Map<String, Object?> _headerValues(
    Order order, {
    required String customerCode,
    required String salesDate,
    bool isVoided = false,
    bool includeServiceChargeFlag = false,
  }) => {
    'Bill_No': int.parse(order.billNo!),
    'Ref_No': order.refNo,
    'Ref_Type': _refType(order.type),
    'Counter_No': SessionProvider.currentCounterNo,
    'Customer_Code': customerCode,
    'Customer_Name': order.customerName,
    'PAX': order.pax ?? 1,
    'Taxable': 0,
    'Header_Ref': null,
    'Header_Ref1': order.orderNote,
    'Bill_Date': _dateOnly(order.createdAt),
    'Bill_Time': _timeOnly(order.createdAt),
    'Sales_Date': salesDate,
    'Bill_Value': order.subtotal,
    'Print_Count': 0,
    'Tax_Total': 0,
    'Service_Charge': 0,
    'Recall_Bill_Flag': isVoided ? 1 : 0,
    if (includeServiceChargeFlag) 'SC_Included': 0,
  };

  /// Stores database bill dates without a time component.
  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Stores database bill times without seconds or fractional seconds.
  String _timeOnly(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

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
