part of '../dinein_page.dart';

class _CartLine {
  const _CartLine(
    this.item,
    this.quantity, {
    this.note = '',
    this.existingQuantity = 0,
    this.isVoided = false,
  });
  final DineInMenuItem item;
  final int quantity;
  final String note;
  final int existingQuantity;
  final bool isVoided;

  bool get hasPendingAdditions => quantity > existingQuantity;
  int get pendingQuantity =>
      hasPendingAdditions ? quantity - existingQuantity : 0;
}

enum _DineInCartSheetAction { confirmOrder, confirmExistingQuantity }

class _DineInCartSheetResult {
  const _DineInCartSheetResult.confirmOrder()
    : action = _DineInCartSheetAction.confirmOrder,
      line = null;

  const _DineInCartSheetResult.confirmExistingQuantity(this.line)
    : action = _DineInCartSheetAction.confirmExistingQuantity;

  final _DineInCartSheetAction action;
  final _CartLine? line;
}
