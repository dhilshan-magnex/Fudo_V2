part of '../billing_page.dart';

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
        Expanded(flex: _orderRefNoColumnFlex, child: _ColumnLabel('REF NO')),
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
          Expanded(
            flex: _orderRefNoColumnFlex,
            child: Text(
              order.refNo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: GlobalColors.primaryText,
                fontSize: isMobile ? 13 : 16,
                fontWeight: FontWeight.w600,
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
  const _RunningOrder(
    this.billId,
    this.type,
    this.refNo,
    this.confirmed,
    this.isCompleted,
  );
  final String billId;
  final String type;
  final String refNo;
  final ConfirmedOrder? confirmed;
  final bool isCompleted;
}
