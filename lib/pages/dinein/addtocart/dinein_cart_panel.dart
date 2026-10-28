part of '../dinein_page.dart';

class _CartButton extends StatelessWidget {
  const _CartButton({required this.itemCount, required this.onPressed});

  final int itemCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      FloatingActionButton(
        tooltip: 'View cart',
        backgroundColor: GlobalColors.homeActionBackground,
        foregroundColor: Colors.white,
        onPressed: onPressed,
        child: const Icon(Icons.shopping_cart_outlined),
      ),
      if (itemCount > 0)
        Positioned(
          right: -4,
          top: -4,
          child: CircleAvatar(
            radius: 11,
            backgroundColor: Colors.redAccent,
            child: Text(
              '$itemCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
    ],
  );
}

class _DineInCartPage extends StatelessWidget {
  const _DineInCartPage({
    required this.cart,
    required this.updatePage,
    required this.onConfirm,
    required this.confirmLabel,
    required this.onEditNote,
    required this.canConfirm,
    required this.showNewItemHighlight,
    required this.canEditExistingItems,
    required this.onEnableExistingItemEdits,
    required this.onConfirmExistingQuantity,
  });

  final Map<String, _CartLine> cart;
  final void Function(VoidCallback) updatePage;
  final Future<void> Function() onConfirm;
  final String confirmLabel;
  final Future<void> Function(_CartLine) onEditNote;
  final bool Function() canConfirm;
  final bool showNewItemHighlight;
  final bool canEditExistingItems;
  final VoidCallback onEnableExistingItemEdits;
  final Future<bool> Function(_CartLine) onConfirmExistingQuantity;

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.values.fold<double>(
      0,
      (total, line) => total + line.item.price * line.quantity,
    );
    final itemCount = cart.values.fold<int>(
      0,
      (total, line) =>
          total + (showNewItemHighlight ? line.pendingQuantity : line.quantity),
    );

    void changeQuantity(_CartLine line, int change) {
      updatePage(() {
        final quantity = line.quantity + change;
        final minimumQuantity =
            canEditExistingItems && line.existingQuantity > 0
            ? 1
            : line.existingQuantity;
        if (quantity <= minimumQuantity) {
          if (line.existingQuantity == 0) {
            cart.remove(line.item.id);
          } else {
            cart[line.item.id] = _CartLine(
              line.item,
              minimumQuantity,
              note: line.note,
              existingQuantity: line.existingQuantity,
            );
          }
        } else {
          cart[line.item.id] = _CartLine(
            line.item,
            quantity,
            note: line.note,
            existingQuantity: line.existingQuantity,
          );
        }
      });
    }

    Future<void> removeSelectedItem(_CartLine line) async {
      final confirmed = await _confirmVoidAllItems(context);
      if (!confirmed) {
        onEnableExistingItemEdits();
        return;
      }

      updatePage(() {
        if (line.existingQuantity == 0) {
          cart.remove(line.item.id);
        } else {
          cart[line.item.id] = _CartLine(
            line.item,
            line.existingQuantity,
            note: line.note,
            existingQuantity: line.existingQuantity,
          );
        }
      });
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GlobalColors.billingCardBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  color: GlobalColors.homeActionBackground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your cart ($itemCount items)',
                    style: const TextStyle(
                      color: GlobalColors.primaryText,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: GlobalColors.billingCardBorder),
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Text(
                      'Your cart is empty.',
                      style: TextStyle(color: GlobalColors.secondaryText),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                      for (final line in cart.values.toList())
                        Card(
                          color:
                              showNewItemHighlight && line.hasPendingAdditions
                              ? const Color(0xFF90EE90)
                              : AppPalette.white,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color:
                                  showNewItemHighlight &&
                                      line.hasPendingAdditions
                                  ? const Color(0xFFE4B65F)
                                  : GlobalColors.billingCardBorder,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        line.item.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: GlobalColors.primaryText,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (showNewItemHighlight &&
                                        line.hasPendingAdditions)
                                      const _PendingCartItemBadge(),
                                    IconButton(
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 36,
                                            height: 36,
                                          ),
                                      padding: EdgeInsets.zero,
                                      tooltip: 'Remove item',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                      ),
                                      color: GlobalColors.secondaryText,
                                      onPressed: line.hasPendingAdditions ||
                                              (showNewItemHighlight &&
                                                  line.existingQuantity > 0)
                                          ? () => removeSelectedItem(line)
                                          : null,
                                    ),
                                  ],
                                ),
                                Text(
                                  'Unit price  ${_cartPriceFormat.format(line.item.price)}',
                                  style: const TextStyle(
                                    color: GlobalColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => onEditNote(line),
                                  icon: const Icon(
                                    Icons.edit_note_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    line.note.isEmpty
                                        ? 'Add note'
                                        : 'Edit note',
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 32),
                                    alignment: Alignment.centerLeft,
                                  ),
                                ),
                                if (line.note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      'Note: ${line.note}',
                                      style: const TextStyle(
                                        color: GlobalColors.secondaryText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                Row(
                                  children: [
                                    IconButton(
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 36,
                                            height: 36,
                                          ),
                                      padding: EdgeInsets.zero,
                                      tooltip: 'Decrease quantity',
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 20,
                                      ),
                                      color: GlobalColors.homeActionBackground,
                                      onPressed: line.quantity <=
                                              (canEditExistingItems &&
                                                      line.existingQuantity > 0
                                                  ? 1
                                                  : line.existingQuantity)
                                          ? null
                                          : () => changeQuantity(line, -1),
                                    ),
                                    Text('${line.quantity}'),
                                    if (canEditExistingItems &&
                                        line.existingQuantity > 0 &&
                                        line.quantity != line.existingQuantity)
                                      IconButton(
                                        constraints:
                                            const BoxConstraints.tightFor(
                                              width: 36,
                                              height: 36,
                                            ),
                                        padding: EdgeInsets.zero,
                                        tooltip: 'Confirm quantity',
                                        icon: const Icon(Icons.check, size: 20),
                                        onPressed: () async {
                                          if (await onConfirmExistingQuantity(
                                            line,
                                          )) {
                                            updatePage(() {
                                              cart[line.item.id] = _CartLine(
                                                line.item,
                                                line.quantity,
                                                note: line.note,
                                                existingQuantity: line.quantity,
                                              );
                                            });
                                            await onConfirm();
                                          }
                                        },
                                      ),
                                    IconButton(
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 36,
                                            height: 36,
                                          ),
                                      padding: EdgeInsets.zero,
                                      tooltip: 'Increase quantity',
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        size: 20,
                                      ),
                                      color: GlobalColors.homeActionBackground,
                                      onPressed: showNewItemHighlight &&
                                              line.existingQuantity > 0 &&
                                              (!canEditExistingItems ||
                                                  line.quantity >=
                                                      line.existingQuantity)
                                          ? null
                                          : () => changeQuantity(line, 1),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _cartPriceFormat.format(
                                        line.item.price * line.quantity,
                                      ),
                                      style: const TextStyle(
                                        color: GlobalColors.primaryText,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(
                    color: GlobalColors.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _cartPriceFormat.format(subtotal),
                  style: const TextStyle(
                    color: GlobalColors.homeActionBackground,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: !canConfirm() ? null : () async => await onConfirm(),
                icon: const Icon(Icons.check_rounded),
                label: Text(confirmLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalColors.homeActionBackground,
                  foregroundColor: GlobalColors.homeHeaderForeground,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

