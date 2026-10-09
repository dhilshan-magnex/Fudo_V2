part of 'billing_page.dart';

class _BillingContent extends StatelessWidget {
  const _BillingContent({
    required this.orders,
    required this.actions,
    required this.isMobile,
    this.fitScreen = false,
  });

  final List<_RunningOrder> orders;
  final List<_BillingAction> actions;
  final bool isMobile;
  final bool fitScreen;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(count: orders.length),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: _RunningOrdersCard(
                orders: orders,
                isMobile: true,
                scrollable: true,
              ),
            ),
            const SizedBox(height: 24),
            _OrderTypeActions(actions: actions, isMobile: true),
          ],
        ),
      );
    }

    if (!fitScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(count: orders.length),
          const SizedBox(height: 12),
          _RunningOrdersCard(orders: orders, isMobile: isMobile),
          SizedBox(height: isMobile ? 28 : 36),
          _OrderTypeActions(actions: actions, isMobile: isMobile),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(count: orders.length),
        const SizedBox(height: 12),
        Expanded(
          flex: 3,
          child: _RunningOrdersCard(
            orders: orders,
            isMobile: isMobile,
            scrollable: true,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 2,
          child: _OrderTypeActions(actions: actions, isMobile: false),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: Text(
          'Orders',
          style: TextStyle(
            color: GlobalColors.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Container(
        constraints: const BoxConstraints(minWidth: 36),
        height: 30,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: GlobalColors.homeActionBackground,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _RunningOrdersCard extends StatelessWidget {
  const _RunningOrdersCard({
    required this.orders,
    required this.isMobile,
    this.scrollable = false,
  });
  final List<_RunningOrder> orders;
  final bool isMobile;
  final bool scrollable;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: GlobalColors.billingCardBorder),
      borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
    ),
    child: Column(
      children: [
        _OrderListHeader(isMobile: isMobile),
        if (scrollable)
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text('No orders yet.'))
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    primary: false,
                    itemCount: orders.length,
                    itemBuilder: (context, index) => _OrderListRow(
                      order: orders[index],
                      isMobile: isMobile,
                      showDivider: true,
                    ),
                  ),
          )
        else if (orders.isEmpty)
          const SizedBox(
            height: 120,
            child: Center(child: Text('No orders yet.')),
          )
        else
          for (var index = 0; index < orders.length; index++)
            _OrderListRow(
              order: orders[index],
              isMobile: isMobile,
              showDivider: index != orders.length - 1,
            ),
      ],
    ),
  );
}

class _OrderListHeader extends StatelessWidget {
  const _OrderListHeader({required this.isMobile});
  final bool isMobile;
  @override
  Widget build(BuildContext context) => Container(
    height: isMobile ? 40 : 52,
    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
    color: GlobalColors.billingHeaderBackground,
    child: const Row(
      children: [
        Expanded(flex: _orderIdColumnFlex, child: _ColumnLabel('BILL ID')),
        Expanded(flex: _orderTypeColumnFlex, child: _ColumnLabel('ORDER TYPE')),
        SizedBox(width: _orderActionColumnWidth),
      ],
    ),
  );
}

class _ColumnLabel extends StatelessWidget {
  const _ColumnLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          color: GlobalColors.billingHeaderText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    ),
  );
}

class _OrderListRow extends StatelessWidget {
  const _OrderListRow({
    required this.order,
    required this.isMobile,
    required this.showDivider,
  });
  final _RunningOrder order;
  final bool isMobile;
  final bool showDivider;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: order.confirmed == null
        ? null
        : () => _showConfirmedOrder(
            context,
            order.confirmed!,
            isCompleted: order.isCompleted,
          ),
    child: Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: order.isCompleted ? const Color(0xFFF9FCFA) : Colors.white,
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: GlobalColors.billingRowDivider),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: _orderIdColumnFlex,
            child: Text(
              order.billId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: GlobalColors.primaryText,
                fontSize: isMobile ? 14 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: _orderTypeColumnFlex,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _OrderTypeChip(type: order.type),
              ),
            ),
          ),
          const SizedBox(
            width: _orderActionColumnWidth,
            child: Center(
              child: Icon(
                Icons.chevron_right_rounded,
                color: GlobalColors.billingChevron,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OrderTypeChip extends StatelessWidget {
  const _OrderTypeChip({required this.type});
  final String type;
  @override
  Widget build(BuildContext context) {
    final colors = switch (type) {
      'Table' => (const Color(0xFFE2ECF9), const Color(0xFF31588E)),
      'Take Away' => (const Color(0xFFFFEBC5), const Color(0xFF975400)),
      'Dine In' => (const Color(0xFFDDF0EF), const Color(0xFF216871)),
      'Delivery' => (const Color(0xFFE7E5FA), const Color(0xFF4A43A4)),
      _ => (const Color(0xFFF9E0E7), const Color(0xFF9B2D50)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: colors.$2, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            type,
            style: TextStyle(
              color: colors.$2,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RunningOrder {
  const _RunningOrder(this.billId, this.type, this.confirmed, this.isCompleted);
  final String billId;
  final String type;
  final ConfirmedOrder? confirmed;
  final bool isCompleted;
}

void _showConfirmedOrder(
  BuildContext context,
  ConfirmedOrder order, {
  required bool isCompleted,
}) {
  final priceFormat = NumberFormat('#,##0.00');
  showModalBottomSheet<void>(
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
                  for (var index = 0; index < order.items.length; index++) ...[
                    if (index > 0)
                      const Divider(
                        height: 1,
                        color: GlobalColors.billingRowDivider,
                      ),
                    Padding(
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
                                  order.items[index].name,
                                  style: const TextStyle(
                                    color: GlobalColors.primaryText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${order.items[index].quantity} × ${priceFormat.format(order.items[index].unitPrice)}',
                                  style: const TextStyle(
                                    color: GlobalColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                                if (order.items[index].note.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Note: ${order.items[index].note}',
                                    style: const TextStyle(
                                      color: GlobalColors.secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            priceFormat.format(order.items[index].subtotal),
                            style: const TextStyle(
                              color: GlobalColors.primaryText,
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
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        context.read<RunningOrdersStore>().completeOrder(
                          order.billId,
                        );
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
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<bool>(
                          builder: (_) => DineInPage(orderToUpdate: order),
                        ),
                      );
                    },
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
