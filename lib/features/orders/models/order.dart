class OrderItem {
  const OrderItem({required this.id, required this.name, required this.quantity, required this.unitPrice, this.note = ''});
  final String id;
  final String name;
  final int quantity;
  final double unitPrice;
  final String note;
  double get subtotal => quantity * unitPrice;
  Map<String, Object?> toRow(String refNo) => {'order_ref_no': refNo, 'item_id': id, 'name': name, 'quantity': quantity, 'unit_price': unitPrice, 'note': note};
  factory OrderItem.fromRow(Map<String, Object?> row) => OrderItem(id: row['item_id']! as String, name: row['name']! as String, quantity: row['quantity']! as int, unitPrice: (row['unit_price']! as num).toDouble(), note: row['note'] as String? ?? '');
}

enum OrderStatus { open, paid, voided }

class Order {
  const Order({required this.refNo, required this.type, required this.items, required this.status, required this.createdAt, required this.posId, this.billNo, this.tableNumber, this.customerName, this.customerPhone, this.deliveryAddress, this.deliveryArea, this.orderNote, this.waiterName, this.pax});
  final String refNo;
  final String? billNo;
  final String type;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final String posId;
  final String? tableNumber, customerName, customerPhone, deliveryAddress, deliveryArea, orderNote, waiterName;
  final int? pax;
  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  Order copyWith({String? billNo, OrderStatus? status, List<OrderItem>? items}) => Order(refNo: refNo, billNo: billNo ?? this.billNo, type: type, items: items ?? this.items, status: status ?? this.status, createdAt: createdAt, posId: posId, tableNumber: tableNumber, customerName: customerName, customerPhone: customerPhone, deliveryAddress: deliveryAddress, deliveryArea: deliveryArea, orderNote: orderNote, waiterName: waiterName, pax: pax);
  Map<String, Object?> toRow() => {'ref_no': refNo, 'bill_no': billNo, 'type': type, 'status': status.name, 'created_at': createdAt.toUtc().toIso8601String(), 'pos_id': posId, 'table_number': tableNumber, 'customer_name': customerName, 'customer_phone': customerPhone, 'delivery_address': deliveryAddress, 'delivery_area': deliveryArea, 'order_note': orderNote, 'waiter_name': waiterName, 'pax': pax};
  factory Order.fromRow(Map<String, Object?> row, List<OrderItem> items) => Order(refNo: row['ref_no']! as String, billNo: row['bill_no'] as String?, type: row['type']! as String, items: items, status: OrderStatus.values.byName(row['status']! as String), createdAt: DateTime.parse(row['created_at']! as String).toLocal(), posId: row['pos_id']! as String, tableNumber: row['table_number'] as String?, customerName: row['customer_name'] as String?, customerPhone: row['customer_phone'] as String?, deliveryAddress: row['delivery_address'] as String?, deliveryArea: row['delivery_area'] as String?, orderNote: row['order_note'] as String?, waiterName: row['waiter_name'] as String?, pax: row['pax'] as int?);
}
