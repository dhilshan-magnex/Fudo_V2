part of '../dinein_page.dart';

class _CartLine {
  const _CartLine(
    this.item,
    this.quantity, {
    this.note = '',
    this.existingQuantity = 0,
  });
  final DineInMenuItem item;
  final int quantity;
  final String note;
  final int existingQuantity;

  bool get hasPendingAdditions => quantity > existingQuantity;
  int get pendingQuantity =>
      hasPendingAdditions ? quantity - existingQuantity : 0;
}

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
