part of '../table_page.dart';

// Owns page state, lifecycle, and actions; layout is implemented by the view.
abstract class _TableController extends State<TablePage> {
  ConfirmedOrder _asConfirmedOrder(Order order) => ConfirmedOrder(
    billId: order.billNo!,
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
    orderNote: order.orderNote,
    waiterName: order.waiterName,
    pax: order.pax,
  );
  String? _selectedSectionId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<TableLayoutProvider>().load();
    });
    Future.microtask(() {
      if (mounted) context.read<OrderProvider>().load();
    });
  }

  void _reload() {
    context.read<TableLayoutProvider>().load();
    context.read<OrderProvider>().load();
  }

  Future<void> _selectTable(TableLayoutTable table) async {
    final orderProvider = context.read<OrderProvider>();
    final existingOrder = await orderProvider.getTableOrder(table.number);
    if (!mounted) return;
    if (existingOrder != null) {
      final confirmedOrder = _asConfirmedOrder(existingOrder);
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => DineInPage(orderToUpdate: confirmedOrder),
        ),
      );
      if (result == true && mounted) {
        await orderProvider.load();
      }
      return;
    }

    final session = context.read<SessionProvider>();
    final details = await showDialog<_TableOrderDetails>(
      context: context,
      builder: (_) => _TableDetailsDialog(
        table: table,
        // The session's _clientName is exposed through clientName.
        waiterName: session.userName?.trim().isNotEmpty == true
            ? session.userName!.trim()
            : session.clientName?.trim() ?? '',
      ),
    );

    if (details != null && mounted) {
      widget.onTableSelected?.call(table);
      final orderConfirmed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => DineInPage(
            tableNumber: table.number,
            customerName: details.customerName,
            waiterName: details.waiterName,
            pax: details.pax,
          ),
        ),
      );
      if (orderConfirmed == true && mounted) {
        await orderProvider.load();
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    }
  }
}
