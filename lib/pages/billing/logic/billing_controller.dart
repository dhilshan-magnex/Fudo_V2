part of '../billing_page.dart';

// Owns page state, lifecycle, and actions; layout is implemented by the view.
abstract class _BillingController extends State<BillingPage> {
  List<_RunningOrder> _runningOrders(List<Order> orders) => orders
      .where((order) => order.status != OrderStatus.voided)
      .map(
        (order) => _RunningOrder(
          order.billNo ?? order.refNo,
          order.type,
          order.refNo,
          _asConfirmedOrder(order),
          order.status == OrderStatus.paid,
        ),
      )
      .toList();
  ConfirmedOrder _asConfirmedOrder(Order order) => ConfirmedOrder(
    billId: order.billNo ?? order.refNo,
    refNo: order.refNo,
    type: order.type,
    items: order.items
        .map(
          (item) => ConfirmedOrderItem(
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            note: item.note,
          ),
        )
        .toList(growable: false),
    tableNumber: order.tableNumber,
    customerName: order.customerName,
    customerPhone: order.customerPhone,
    deliveryAddress: order.deliveryAddress,
    deliveryArea: order.deliveryArea,
    orderNote: order.orderNote,
    waiterName: order.waiterName,
    pax: order.pax,
  );
  bool _hasBillingAccess = false;

  @override
  void initState() {
    super.initState();
    _checkBillingAccess();
  }

  Future<void> _checkBillingAccess() async {
    final groupCode = context.read<SessionProvider>().groupCode;

    if (groupCode == null || groupCode.trim().isEmpty) {
      await _showAccessDialog(
        title: 'Access unavailable',
        message: 'User group information is unavailable.',
      );
      return;
    }

    final allowed = await AccessControlService.checkAccess(
      groupCode: groupCode,
      screenId: AppFunctions.billingScreen,
      functionId: AppFunctions.billing,
    );

    if (!mounted) {
      return;
    }

    if (!allowed) {
      await _showAccessDialog();
      return;
    }

    setState(() {
      _hasBillingAccess = true;
    });
  }

  Future<void> _showAccessDialog({
    String title = 'Access denied',
    String message = 'You do not have permission to use this feature.',
  });
}
