import 'package:flutter/foundation.dart';

class ConfirmedOrderItem {
  const ConfirmedOrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String id;
  final String name;
  final int quantity;
  final double unitPrice;

  double get subtotal => quantity * unitPrice;
}

class ConfirmedOrder {
  const ConfirmedOrder({
    required this.billId,
    required this.type,
    required this.items,
    this.tableNumber,
    this.customerName,
    this.waiterName,
    this.pax,
  });

  final String billId;
  final String type;
  final List<ConfirmedOrderItem> items;
  final String? tableNumber;
  final String? customerName;
  final String? waiterName;
  final int? pax;

  double get subtotal =>
      items.fold(0, (total, item) => total + item.subtotal);
}

/// Holds confirmed orders for the current app session.
class RunningOrdersStore extends ChangeNotifier {
  final List<ConfirmedOrder> _orders = [];
  int _nextBillNumber = 39;

  List<ConfirmedOrder> get orders => List.unmodifiable(_orders);

  ConfirmedOrder addOrder({
    required List<ConfirmedOrderItem> items,
    String? tableNumber,
    String? customerName,
    String? waiterName,
    int? pax,
  }) {
    if (items.isEmpty) {
      throw ArgumentError('An order must contain at least one item.');
    }
    final order = ConfirmedOrder(
      billId: 'B-${_nextBillNumber.toString().padLeft(4, '0')}',
      type: tableNumber == null ? 'Dine In' : 'Table',
      items: List.unmodifiable(items),
      tableNumber: tableNumber,
      customerName: customerName,
      waiterName: waiterName,
      pax: pax,
    );
    _nextBillNumber++;
    _orders.insert(0, order);
    notifyListeners();
    return order;
  }
}
