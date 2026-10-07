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
              height: 240,
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
          'Running Orders',
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
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) => _OrderListRow(
                order: orders[index],
                isMobile: isMobile,
                showDivider: index != orders.length - 1,
              ),
            ),
          )
        else if (orders.isEmpty)
          const Expanded(
            child: Center(child: Text('No running orders yet.')),
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
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: GlobalColors.billingHeaderText,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
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
        : () => _showConfirmedOrder(context, order.confirmed!),
    child: Container(
      height: isMobile ? 40 : 72,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
      decoration: BoxDecoration(
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
              style: TextStyle(
                color: GlobalColors.primaryText,
                fontSize: isMobile ? 14 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: _orderTypeColumnFlex,
            child: _OrderTypeChip(type: order.type),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Container(
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
                decoration: BoxDecoration(
                  color: colors.$2,
                  shape: BoxShape.circle,
                ),
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
        ),
      ),
    );
  }
}

class _RunningOrder {
  const _RunningOrder(this.billId, this.type, this.confirmed);
  final String billId;
  final String type;
  final ConfirmedOrder? confirmed;
}

void _showConfirmedOrder(BuildContext context, ConfirmedOrder order) {
  final priceFormat = NumberFormat('#,##0.00');
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(order.billId,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          if (order.tableNumber != null) Text('Table ${order.tableNumber}'),
          if (order.customerName != null) Text('Customer: ${order.customerName}'),
          if (order.waiterName != null) Text('Waiter: ${order.waiterName}'),
          if (order.pax != null) Text('Pax: ${order.pax}'),
          const Divider(),
          for (final item in order.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              subtitle: Text('${item.quantity} x ${priceFormat.format(item.unitPrice)}'),
              trailing: Text(priceFormat.format(item.subtotal)),
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(fontWeight: FontWeight.w700)),
              Text(priceFormat.format(order.subtotal),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ], 
      ),
    ),
  );
}
