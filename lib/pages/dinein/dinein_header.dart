part of 'dinein_page.dart';

class _DineInHeader extends StatelessWidget {
  const _DineInHeader({
    required this.cartPage,
    required this.onBack,
  });

  final Widget cartPage;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 500;
      final isTablet = AppLayoutType.fromContext(context).isTablet;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'FUDO V2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              SizedBox(
                width: compact ? 96 : 112,
                height: 56,
                child: FudoBackButton(onPressed: onBack),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 24),
          Text(
            'Dine In',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 26 : 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select items for the table order',
            style: TextStyle(
              color: GlobalColors.homeHeaderLabel,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isTablet) ...[
            if (constraints.hasBoundedHeight)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: cartPage,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(height: 420, child: cartPage),
              ),
          ],
        ],
      );
    },
  );
}
