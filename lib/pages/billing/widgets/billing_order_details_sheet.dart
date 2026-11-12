part of '../billing_page.dart';

Future<bool?> _showBillingOrderDetailsSheet(
  BuildContext context,
  ConfirmedOrder order, {
  required bool isCompleted,
  required List<ConfirmedOrderItem> detailItems,
  required Future<void> Function() onCheckout,
}) {
  final priceFormat = NumberFormat('#,##0.00');
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: GlobalColors.homeBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: GlobalColors.homeHeaderBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ORDER DETAILS',
                    style: TextStyle(
                      color: GlobalColors.homeHeaderLabel,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.billId,
                    style: const TextStyle(
                      color: GlobalColors.homeHeaderForeground,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [_OrderTypeChip(type: order.type)],
                  ),
                ],
              ),
            ),
            if (order.tableNumber != null ||
                order.customerName != null ||
                order.customerPhone != null ||
                order.deliveryAddress != null ||
                order.deliveryArea != null ||
                order.orderNote != null ||
                order.waiterName != null ||
                order.pax != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: GlobalColors.billingCardBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    if (order.tableNumber != null)
                      _OrderSheetInfo('TABLE', order.tableNumber!),
                    if (order.customerName != null)
                      _OrderSheetInfo('CUSTOMER', order.customerName!),
                    if (order.customerPhone != null)
                      _OrderSheetInfo('PHONE', order.customerPhone!),
                    if (order.deliveryAddress != null)
                      _OrderSheetInfo('ADDRESS', order.deliveryAddress!),
                    if (order.deliveryArea != null)
                      _OrderSheetInfo('AREA', order.deliveryArea!),
                    if (order.orderNote != null)
                      _OrderSheetInfo('ORDER NOTE', order.orderNote!),
                    if (order.waiterName != null)
                      _OrderSheetInfo('WAITER', order.waiterName!),
                    if (order.pax != null)
                      _OrderSheetInfo('PAX', '${order.pax}'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: GlobalColors.billingCardBorder),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: GlobalColors.billingHeaderBackground,
                    child: const Text(
                      'ORDER ITEMS',
                      style: TextStyle(
                        color: GlobalColors.billingHeaderText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  for (var index = 0; index < detailItems.length; index++) ...[
                    if (index > 0)
                      const Divider(
                        height: 1,
                        color: GlobalColors.billingRowDivider,
                      ),
                    Container(
                      color: detailItems[index].isVoided
                          ? const Color(0xFFFFF0F0)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detailItems[index].name,
                                  style: TextStyle(
                                    color: detailItems[index].isVoided
                                        ? const Color(0xFFB3261E)
                                        : GlobalColors.primaryText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 4),
                                Text(
                                  '${detailItems[index].quantity} × ${priceFormat.format(detailItems[index].unitPrice)}',
                                  style: TextStyle(
                                    color: detailItems[index].isVoided
                                        ? const Color(0xFFB3261E)
                                        : GlobalColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                                if (detailItems[index].isVoided)
                                  const Text(
                                    'VOIDED',
                                    style: TextStyle(
                                      color: Color(0xFFB3261E),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                if (detailItems[index].note.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${detailItems[index].isVoided ? 'Reason' : 'Note'}: ${detailItems[index].note}',
                                    style: TextStyle(
                                      color: detailItems[index].isVoided
                                          ? const Color(0xFFB3261E)
                                          : GlobalColors.secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            priceFormat.format(detailItems[index].subtotal),
                            style: TextStyle(
                              color: detailItems[index].isVoided
                                  ? const Color(0xFFB3261E)
                                  : GlobalColors.primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: GlobalColors.billingCardBorder),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtotal',
                    style: TextStyle(
                      color: GlobalColors.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    priceFormat.format(order.subtotal),
                    style: const TextStyle(
                      color: GlobalColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (!isCompleted)
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: GlobalColors.homeActionBackground,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        await onCheckout();
                        if (!context.mounted) return;
                      },
                      icon: const Icon(Icons.point_of_sale_rounded),
                      label: const Text('Checkout'),
                    ),
                  ),
                if (!isCompleted) const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('Add Items'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _OrderSheetInfo extends StatelessWidget {
  const _OrderSheetInfo(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: GlobalColors.billingHeaderText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: GlobalColors.primaryText,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
