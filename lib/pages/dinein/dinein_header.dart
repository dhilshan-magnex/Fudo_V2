part of 'dinein_page.dart';

class _DineInHeader extends StatelessWidget {
  const _DineInHeader();

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
                child: const FudoBackButton(),
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
        ],
      );
    },
  );
}
