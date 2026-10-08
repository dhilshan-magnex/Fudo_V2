import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../function/app_functions.dart';
import '../../layout/layout.dart';
import '../../services/access_control_service.dart';
import '../../session/session_provider.dart';
import '../../session/running_orders_store.dart';
import '../../utils/global_colors.dart';
import '../../widgets/authorization.dart';
import '../../widgets/buttons/back_button.dart';
import '../../widgets/buttons/button.dart';
import '../dinein/dinein_page.dart';
import '../table/table_page.dart';

part 'billing_header.dart';
part 'billing_order_table.dart';
part 'billing_buttons.dart';

const _orderIdColumnFlex = 9;
const _orderTypeColumnFlex = 10;
const _orderStatusColumnFlex = 11;
const _orderActionColumnWidth = 24.0;

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  static const _actions = <_BillingAction>[
    _BillingAction('Table', Icons.table_restaurant_outlined),
    _BillingAction('Take Away', Icons.shopping_bag_outlined),
    _BillingAction('Delivery', Icons.delivery_dining_outlined),
    _BillingAction('Dine In', Icons.restaurant_outlined),
    _BillingAction('Online', Icons.language_outlined),
    _BillingAction('More', Icons.more_horiz),
  ];

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

    final orderStore = context.watch<RunningOrdersStore>();
    final orders = orderStore.orders
        .map(
          (order) => _RunningOrder(
            order.billId,
            order.type,
            order,
            orderStore.isCompleted(order.billId),
          ),
        )
        .toList();

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
