part of 'billing_page.dart';

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
                  MaterialPageRoute<bool>(builder: (_) => const DineInPage()),
                );
              }
            },
          );
        },
      );
    },
  );
}

class _BillingAction {
  const _BillingAction(this.label, this.icon);
  final String label;
  final IconData icon;
}
