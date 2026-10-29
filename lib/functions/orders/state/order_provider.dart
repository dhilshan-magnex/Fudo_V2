import 'package:flutter/foundation.dart';
import '../data/order_repository.dart';
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider(this._repository);
  final OrderRepository _repository;
  List<Order> _orders = const [];
  bool _isLoading = false;
  Object? _error;
  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  Object? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await _repository.getAll();
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order> createOrder({
    required String posId,
    required String type,
    required List<OrderItem> items,
    String? tableNumber,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? deliveryArea,
    String? orderNote,
    String? waiterName,
    int? pax,
  }) async {
    if (posId.trim().isEmpty) {
      throw ArgumentError.value(posId, 'posId', 'cannot be empty');
    }
    if (items.isEmpty) {
      throw ArgumentError('An order must contain at least one item.');
    }
    final order = Order(
      refNo: await _repository.createRefNo(
        type: type,
        tableNumber: tableNumber,
      ),
      type: type,
      items: List.unmodifiable(items),
      status: OrderStatus.open,
      createdAt: DateTime.now(),
      posId: posId.trim(),
      tableNumber: tableNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      deliveryArea: deliveryArea,
      orderNote: orderNote,
      waiterName: waiterName,
      pax: pax ?? 1,
    );
    final savedOrder = await _repository.createOrder(order);
    _orders = [savedOrder, ..._orders];
    notifyListeners();
    return savedOrder;
  }

  Future<String> finalizeBill(String refNo) async {
    final billNo = await _repository.assignNextBillNo(refNo);
    _orders = await _repository.getAll();
    notifyListeners();
    return billNo;
  }

  Future<void> checkoutOrder(String billNo) async {
    await _repository.recordCheckout(billNo);
    _orders = await _repository.getAll();
    notifyListeners();
  }

  Future<void> addItemsToOrder({
    required String billNo,
    required String refNo,
    required String type,
    required List<OrderItem> items,
    String? tableNumber,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? deliveryArea,
    String? orderNote,
    String? waiterName,
    int? pax,
  }) async {
    await _repository.addItemsToOrder(
      Order(
        billNo: billNo,
        refNo: refNo,
        type: type,
        items: List.unmodifiable(items),
        status: OrderStatus.open,
        createdAt: DateTime.now(),
        posId: '',
        tableNumber: tableNumber,
        customerName: customerName,
        customerPhone: customerPhone,
        deliveryAddress: deliveryAddress,
        deliveryArea: deliveryArea,
        orderNote: orderNote,
        waiterName: waiterName,
        pax: pax,
      ),
    );
    _orders = await _repository.getAll();
    notifyListeners();
  }

  Future<void> updateOrderItemQuantity({
    required String billNo,
    required String menuId,
    required int quantity,
    required String reason,
  }) async {
    await _repository.updateOrderItemQuantity(
      billNo: billNo,
      menuId: menuId,
      quantity: quantity,
      reason: reason,
    );
    _orders = await _repository.getAll();
    notifyListeners();
  }

  Future<void> deleteOrder(String refNo) async {
    await _repository.delete(refNo);
    _orders = _orders.where((order) => order.refNo != refNo).toList();
    notifyListeners();
  }
}
