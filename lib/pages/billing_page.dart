import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../function/app_functions.dart';
import '../layout/layout.dart';
import '../services/access_control_service.dart';
import '../session/session_provider.dart';
import '../utils/global_colors.dart';
import '../widgets/authorization.dart';
import '../widgets/back_button.dart';
import '../widgets/button.dart';
import 'dinein_page.dart';
import 'table_page.dart';

const _orderIdColumnFlex = 11;
const _orderTypeColumnFlex = 15;
const _orderActionColumnWidth = 24.0;

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  static const _orders = <_RunningOrder>[
    _RunningOrder('B-0031', 'Table'),
    _RunningOrder('B-0032', 'Take Away'),
    _RunningOrder('B-0033', 'Dine In'),
    _RunningOrder('B-0034', 'Delivery'),
    _RunningOrder('B-0035', 'Online'),
    _RunningOrder('B-0036', 'Table'),
    _RunningOrder('B-0037', 'Take Away'),
    _RunningOrder('B-0038', 'Online'),
  ];
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
                    orders: _orders,
                    actions: _actions,
                    isMobile: isMobile,
                  );
                }

                return _BillingContent(
                  orders: _orders,
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

class _BillingHeader extends StatelessWidget {
  const _BillingHeader();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 500;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'FUDO V2',
                  style: TextStyle(
                    color: GlobalColors.homeHeaderForeground,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              SizedBox(
                width: compact ? 96 : 112,
                height: 56,
                child: const FudoBackButton(),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 24),
          Text(
            'Billing',
            style: TextStyle(
              color: GlobalColors.homeHeaderForeground,
              fontSize: compact ? 26 : 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'View running orders or start a new sale',
            style: TextStyle(
              color: GlobalColors.homeHeaderLabel,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    },
  );
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
    onTap: () {},
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

class _OrderTypeActions extends StatelessWidget {
  const _OrderTypeActions({required this.actions, required this.isMobile});
  final List<_BillingAction> actions;
  final bool isMobile;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 230
          ? 1
          : (isMobile ? (constraints.maxWidth >= 315 ? 3 : 2) : 3);
      const spacing = 12.0;
      final rows = (actions.length / columns).ceil();
      final double tileHeight;
      if (isMobile) {
        tileHeight = (constraints.maxWidth / columns * 0.9)
            .clamp(96.0, 156.0)
            .toDouble();
      } else {
        tileHeight =
            ((constraints.maxHeight.isFinite ? constraints.maxHeight : 270.0) -
                (rows - 1) * spacing) /
            rows;
      }
      return GridView.builder(
        shrinkWrap: isMobile || !constraints.maxHeight.isFinite,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          mainAxisExtent: tileHeight,
        ),
        itemBuilder: (context, index) {
          final action = actions[index];
          return HomeActionButton(
            icon: action.icon,
            label: action.label,
            mode: action.label == 'More'
                ? HomeActionButtonMode.compact
                : HomeActionButtonMode.tile,
            backgroundColor: action.label == 'More'
                ? Colors.white
                : GlobalColors.homeActionBackground,
            onTap: () {
              if (action.label == 'Table') {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const TablePage()),
                );
              } else if (action.label == 'Dine In') {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const DineInPage()),
                );
              }
            },
          );
        },
      );
    },
  );
}

class _RunningOrder {
  const _RunningOrder(this.billId, this.type);
  final String billId;
  final String type;
}

class _BillingAction {
  const _BillingAction(this.label, this.icon);
  final String label;
  final IconData icon;
}
