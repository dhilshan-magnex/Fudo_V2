part of '../dinein_page.dart';

class _PendingCartItemBadge extends StatelessWidget {
  const _PendingCartItemBadge();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 8),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE4A8),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text(
      'NEW',
      style: TextStyle(
        color: Color(0xFF975400),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    ),
  );
}

class _VoidedCartItemBadge extends StatelessWidget {
  const _VoidedCartItemBadge();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 8),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFDAD6),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text(
      'VOIDED',
      style: TextStyle(
        color: Color(0xFFB3261E),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    ),
  );
}
