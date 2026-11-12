part of '../billing_page.dart';

class _BillingPageState extends _BillingController {
  static const _actions = <_BillingAction>[
    _BillingAction('Table', Icons.table_restaurant_outlined),
    _BillingAction('Take Away', Icons.shopping_bag_outlined),
    _BillingAction('Delivery', Icons.delivery_dining_outlined),
    _BillingAction('Dine In', Icons.restaurant_outlined),
    _BillingAction('Online', Icons.language_outlined),
    _BillingAction('More', Icons.more_horiz),
  ];

  @override
  Future<void> _showAccessDialog({
    String title = 'Access denied',
    String message = 'You do not have permission to use this feature.',
  }) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AuthorizationDialog(title: title, message: message),
    );

    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasBillingAccess) {
      return const Scaffold(
        backgroundColor: GlobalColors.homeBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final orderProvider = context.watch<OrderProvider>();
    final orders = _runningOrders(orderProvider.orders);

    return Scaffold(
      backgroundColor: GlobalColors.homeBackground,
      body: HomeLayout(
        primaryContent: const _BillingHeader(),
        sideContent: Builder(
          builder: (context) {
            final isMobile = AppLayoutType.fromContext(context).isMobile;
            return LayoutBuilder(
              builder: (context, constraints) {
                if (!constraints.maxHeight.isFinite) {
                  return _BillingContent(
                    orders: orders,
                    actions: _actions,
                    isMobile: isMobile,
                  );
                }

                return _BillingContent(
                  orders: orders,
                  actions: _actions,
                  isMobile: isMobile,
                  fitScreen: true,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
