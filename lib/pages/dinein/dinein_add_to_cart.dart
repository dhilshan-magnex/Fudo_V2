part of 'dinein_page.dart';

final _cartPriceFormat = NumberFormat('#,##0.00');

void _showDineInCart(
  BuildContext context,
  Map<String, _CartLine> cart,
  void Function(VoidCallback) updatePage,
  VoidCallback onConfirm,
  String confirmLabel,
  Future<void> Function(_CartLine) onEditNote,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: GlobalColors.homeBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, refreshSheet) {
        void changeQuantity(_CartLine line, int change) {
          updatePage(() {
            final quantity = line.quantity + change;
            if (quantity <= 0) {
              cart.remove(line.item.id);
            } else {
              cart[line.item.id] = _CartLine(
                line.item,
                quantity,
                note: line.note,
              );
            }
          });
          refreshSheet(() {});
        }

        final subtotal = cart.values.fold<double>(
          0,
          (total, line) => total + line.item.price * line.quantity,
        );
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: GlobalColors.homeHeaderBackground,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        color: GlobalColors.homeHeaderForeground,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Your cart',
                          style: TextStyle(
                            color: GlobalColors.homeHeaderForeground,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${cart.values.fold<int>(0, (sum, line) => sum + line.quantity)} items',
                        style: const TextStyle(
                          color: GlobalColors.homeHeaderLabel,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close cart',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: GlobalColors.homeHeaderForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: cart.isEmpty
                      ? const Center(
                          child: Text(
                            'Your cart is empty.',
                            style: TextStyle(color: GlobalColors.secondaryText),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            for (final line in cart.values.toList())
                              Card(
                                color: AppPalette.white,
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    color: GlobalColors.billingCardBorder,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: ListTile(
                                  title: Text(
                                    line.item.name,
                                    style: const TextStyle(
                                      color: GlobalColors.primaryText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Unit price  ${_cartPriceFormat.format(line.item.price)}',
                                        style: const TextStyle(
                                          color: GlobalColors.secondaryText,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () async {
                                          await onEditNote(line);
                                          refreshSheet(() {});
                                        },
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
                                          alignment: Alignment.centerLeft,
                                        ),
                                      ),
                                      if (line.note.isNotEmpty)
                                        Text(
                                          'Note: ${line.note}',
                                          style: const TextStyle(
                                            color: GlobalColors.secondaryText,
                                            fontSize: 12,
                                          ),
                                        ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Decrease quantity',
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                            ),
                                            color: GlobalColors
                                                .homeActionBackground,
                                            onPressed: () =>
                                                changeQuantity(line, -1),
                                          ),
                                          Text('${line.quantity}'),
                                          IconButton(
                                            tooltip: 'Increase quantity',
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                            color: GlobalColors
                                                .homeActionBackground,
                                            onPressed: () =>
                                                changeQuantity(line, 1),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Line subtotal  ${_cartPriceFormat.format(line.item.price * line.quantity)}',
                                        style: const TextStyle(
                                          color: GlobalColors.primaryText,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    tooltip: 'Remove item',
                                    icon: const Icon(Icons.delete_outline),
                                    color: GlobalColors.secondaryText,
                                    onPressed: () =>
                                        changeQuantity(line, -line.quantity),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppPalette.white,
                    border: Border(
                      top: BorderSide(color: GlobalColors.billingCardBorder),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(
                          color: GlobalColors.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _cartPriceFormat.format(subtotal),
                        style: const TextStyle(
                          color: GlobalColors.homeActionBackground,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: cart.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              onConfirm();
                            },
                      icon: const Icon(Icons.check_rounded),
                      label: Text(confirmLabel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlobalColors.homeActionBackground,
                        foregroundColor: GlobalColors.homeHeaderForeground,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

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
  });

  final Map<String, _CartLine> cart;
  final void Function(VoidCallback) updatePage;
  final VoidCallback onConfirm;
  final String confirmLabel;
  final Future<void> Function(_CartLine) onEditNote;

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.values.fold<double>(
      0,
      (total, line) => total + line.item.price * line.quantity,
    );
    final itemCount = cart.values.fold<int>(
      0,
      (total, line) => total + line.quantity,
    );

    void changeQuantity(_CartLine line, int change) {
      updatePage(() {
        final quantity = line.quantity + change;
        if (quantity <= 0) {
          cart.remove(line.item.id);
        } else {
          cart[line.item.id] = _CartLine(line.item, quantity, note: line.note);
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
                          color: AppPalette.white,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              color: GlobalColors.billingCardBorder,
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
                                      onPressed: () =>
                                          changeQuantity(line, -line.quantity),
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
                                      onPressed: () => changeQuantity(line, -1),
                                    ),
                                    Text('${line.quantity}'),
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
                                      onPressed: () => changeQuantity(line, 1),
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
                onPressed: cart.isEmpty ? null : onConfirm,
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

class _CartLine {
  const _CartLine(this.item, this.quantity, {this.note = ''});
  final DineInMenuItem item;
  final int quantity;
  final String note;
}
