import 'package:flutter/foundation.dart';
import 'package:fudo_v2/functions/orders/models/confirmed_order.dart';

/// Holds confirmed orders for the current app session.
class RunningOrdersStore extends ChangeNotifier {
  final List<ConfirmedOrder> _orders = [];
  final List<ConfirmedOrder> _completedOrders = [];
  int _nextBillNumber = 1;

  List<ConfirmedOrder> get orders =>
      List.unmodifiable([..._orders, ..._completedOrders]);
  List<ConfirmedOrder> get completedOrders =>
      List.unmodifiable(_completedOrders);

  bool isCompleted(String billId) =>
      _completedOrders.any((order) => order.billId == billId);

  void completeOrder(String billId) {
    final index = _orders.indexWhere((order) => order.billId == billId);
    if (index == -1) return;
    _completedOrders.insert(0, _orders.removeAt(index));
    notifyListeners();
  }

  void addItems(String billId, List<ConfirmedOrderItem> items) {
    if (items.isEmpty) {
      throw ArgumentError('At least one item must be added to an order.');
    }

    final activeIndex = _orders.indexWhere((order) => order.billId == billId);
    final completedIndex = _completedOrders.indexWhere(
      (order) => order.billId == billId,
    );
    if (activeIndex == -1 && completedIndex == -1) {
      throw StateError('Order $billId was not found.');
    }

    final order = activeIndex != -1
        ? _orders.removeAt(activeIndex)
        : _completedOrders.removeAt(completedIndex);
    final updatedOrder = ConfirmedOrder(
      billId: order.billId,
      refNo: order.refNo,
      type: order.type,
      items: List.unmodifiable([
        ...order.items.map(
          (item) => ConfirmedOrderItem(
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            note: item.note,
          ),
        ),
        ...items.map(
          (item) => ConfirmedOrderItem(
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            note: item.note,
            isNewlyAdded: true,
          ),
        ),
      ]),
      tableNumber: order.tableNumber,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      deliveryAddress: order.deliveryAddress,
      deliveryArea: order.deliveryArea,
      orderNote: order.orderNote,
      waiterName: order.waiterName,
      pax: order.pax,
    );
    _orders.insert(0, updatedOrder);
    notifyListeners();
  }

  void updateItemQuantity(String billId, String itemId, int quantity) {
    final activeIndex = _orders.indexWhere((order) => order.billId == billId);
    final completedIndex = _completedOrders.indexWhere(
      (order) => order.billId == billId,
    );
    if (activeIndex == -1 && completedIndex == -1) {
      throw StateError('Order $billId was not found.');
    }

    final order = activeIndex != -1
        ? _orders.removeAt(activeIndex)
        : _completedOrders.removeAt(completedIndex);
    final updatedOrder = ConfirmedOrder(
      billId: order.billId,
      refNo: order.refNo,
      type: order.type,
      items: List.unmodifiable(
        order.items.map(
          (item) => item.id == itemId
              ? ConfirmedOrderItem(
                  id: item.id,
                  name: item.name,
                  quantity: quantity,
                  unitPrice: item.unitPrice,
                  note: item.note,
                )
              : item,
        ),
      ),
      tableNumber: order.tableNumber,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      deliveryAddress: order.deliveryAddress,
      deliveryArea: order.deliveryArea,
      orderNote: order.orderNote,
      waiterName: order.waiterName,
      pax: order.pax,
    );
    _orders.insert(0, updatedOrder);
    notifyListeners();
  }

  void deleteOrder(String billId) {
    final previousLength = _orders.length + _completedOrders.length;
    _orders.removeWhere((order) => order.billId == billId);
    _completedOrders.removeWhere((order) => order.billId == billId);
    if (_orders.length + _completedOrders.length != previousLength) {
      notifyListeners();
    }
  }

  ConfirmedOrder addOrder({
    required List<ConfirmedOrderItem> items,
    String? billId,
    String? refNo,
    String? tableNumber,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? deliveryArea,
    String? orderNote,
    String? orderType,
    String? waiterName,
    int? pax,
  }) {
    if (items.isEmpty) {
      throw ArgumentError('An order must contain at least one item.');
    }
    final order = ConfirmedOrder(
      billId: billId ?? 'B-${_nextBillNumber.toString().padLeft(4, '0')}',
      refNo: refNo ?? 'REF-${_nextBillNumber.toString().padLeft(6, '0')}',
      type: orderType ?? (tableNumber == null ? 'Dine In' : 'Table'),
      items: List.unmodifiable(items),
      tableNumber: tableNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      deliveryArea: deliveryArea,
      orderNote: orderNote,
      waiterName: waiterName,
      pax: pax,
    );
    _nextBillNumber++;
    _orders.insert(0, order);
    notifyListeners();
    return order;
  }
}
