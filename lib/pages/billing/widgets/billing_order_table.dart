part of '../billing_page.dart';

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: Text(
          'Orders',
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
