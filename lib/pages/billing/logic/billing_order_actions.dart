part of '../billing_page.dart';

Future<void> _showConfirmedOrder(
  BuildContext context,
  ConfirmedOrder order, {
  required bool isCompleted,
}) async {
  final itemRows = await context.read<OrderProvider>().getBillingItemRows(
    order.billId,
  );
  if (!context.mounted) return;
  final detailItems = itemRows
      .map((row) {
        final isVoided = row['Tran_Type']?.toString() == 'TV';
        return ConfirmedOrderItem(
          id: row['Menu_ID']?.toString() ?? '',
          name: row['Tran_Description']?.toString() ?? '',
          quantity: (row['Tran_Qty'] as num?)?.toInt() ?? 0,
          unitPrice: (row['Unit_Price'] as num?)?.toDouble() ?? 0,
          note: isVoided ? row['Tran_Ref']?.toString() ?? '' : '',
          isVoided: isVoided,
        );
      })
      .toList(growable: false);

  final shouldAddItems = await _showBillingOrderDetailsSheet(
    context,
    order,
    isCompleted: isCompleted,
    detailItems: detailItems,
    onCheckout: () => context.read<OrderProvider>().checkoutOrder(order.billId),
  );

  if (shouldAddItems == true && context.mounted) {
    await context.read<OrderProvider>().markBillOpenForAddItems(order.billId);
    if (!context.mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => DineInPage(orderToUpdate: order)),
    );
  }
}
