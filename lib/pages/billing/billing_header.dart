part of 'billing_page.dart';

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
