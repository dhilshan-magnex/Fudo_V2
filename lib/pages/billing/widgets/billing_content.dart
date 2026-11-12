part of '../billing_page.dart';

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
