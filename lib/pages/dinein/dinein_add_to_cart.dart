part of 'dinein_page.dart';

final _cartPriceFormat = NumberFormat('#,##0.00');

void _showDineInCart(
  BuildContext context,
  Map<String, _CartLine> cart,
  void Function(VoidCallback) updatePage,
  VoidCallback onConfirm,
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
              cart[line.item.id] = _CartLine(line.item, quantity);
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
                      label: const Text('Confirm order'),
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

class _CartLine {
  const _CartLine(this.item, this.quantity);
  final DineInMenuItem item;
  final int quantity;
}
