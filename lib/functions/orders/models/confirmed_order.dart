class ConfirmedOrderItem {
  const ConfirmedOrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.note = '',
    this.isNewlyAdded = false,
    this.isVoided = false,
  });

  final String id;
  final String name;
  final int quantity;
  final double unitPrice;
  final String note;
  final bool isNewlyAdded;
  final bool isVoided;

  double get subtotal => quantity * unitPrice;
}

class ConfirmedOrder {
  const ConfirmedOrder({
    required this.billId,
    required this.refNo,
    required this.type,
    required this.items,
    this.tableNumber,
    this.customerName,
    this.customerPhone,
    this.deliveryAddress,
    this.deliveryArea,
    this.orderNote,
    this.waiterName,
    this.pax,
  });

  final String billId;
  final String refNo;
  final String type;
  final List<ConfirmedOrderItem> items;
  final String? tableNumber;
  final String? customerName;
  final String? customerPhone;
  final String? deliveryAddress;
  final String? deliveryArea;
  final String? orderNote;
  final String? waiterName;
  final int? pax;

  double get subtotal => items.fold(0, (total, item) => total + item.subtotal);
}
