part of '../dinein_page.dart';


final _cartPriceFormat = NumberFormat('#,##0.00');

Future<void> _showDineInCart(
  BuildContext context,
  Map<String, _CartLine> cart,
  void Function(VoidCallback) updatePage,
  Future<void> Function() onConfirm,
  String confirmLabel,
  Future<void> Function(_CartLine) onEditNote,
  bool Function() canConfirm,
  bool showNewItemHighlight,
  bool canEditExistingItems,
  VoidCallback onEnableExistingItemEdits,
  Future<bool> Function(_CartLine) onConfirmExistingQuantity,
) async {
  var isEditingExistingItems = canEditExistingItems;
  final shouldConfirm = await showModalBottomSheet<bool>(
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
            final minimumQuantity =
                isEditingExistingItems && line.existingQuantity > 0
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
          refreshSheet(() {});
        }

        Future<void> removeSelectedItem(_CartLine line) async {
          final confirmed = await _confirmVoidAllItems(context);
          if (!confirmed) {
            isEditingExistingItems = true;
            onEnableExistingItemEdits();
            refreshSheet(() {});
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
          refreshSheet(() {});
        }

        final subtotal = cart.values.fold<double>(
          0,
          (total, line) => total + line.item.price * line.quantity,
        );
        final itemCount = cart.values.fold<int>(
          0,
          (total, line) =>
              total +
              (showNewItemHighlight ? line.pendingQuantity : line.quantity),
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
                        '$itemCount items',
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
                                color:
                                    showNewItemHighlight &&
                                        line.hasPendingAdditions
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
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          line.item.name,
                                          style: const TextStyle(
                                            color: GlobalColors.primaryText,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (showNewItemHighlight &&
                                          line.hasPendingAdditions)
                                        const _PendingCartItemBadge(),
                                    ],
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
                                            onPressed:
                                                line.quantity <=
                                                        (isEditingExistingItems &&
                                                                line.existingQuantity >
                                                                    0
                                                            ? 1
                                                            : line.existingQuantity)
                                                ? null
                                                : () =>
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
                                            onPressed:
                                                showNewItemHighlight &&
                                                        line.existingQuantity > 0 &&
                                                        (!isEditingExistingItems ||
                                                            line.quantity >=
                                                                line.existingQuantity)
                                                ? null
                                                : () =>
                                                      changeQuantity(line, 1),
                                          ),
                                          if (isEditingExistingItems &&
                                              line.existingQuantity > 0 &&
                                              line.quantity !=
                                                  line.existingQuantity)
                                            IconButton(
                                              tooltip: 'Confirm quantity',
                                              icon: const Icon(Icons.check),
                                              onPressed: () async {
                                                if (await onConfirmExistingQuantity(line)) {
                                                  updatePage(() {
                                                    cart[line.item.id] = _CartLine(
                                                      line.item,
                                                      line.quantity,
                                                      note: line.note,
                                                      existingQuantity: line.quantity,
                                                    );
                                                  });
                                                  Navigator.of(context).pop(true);
                                                }
                                              },
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
                                    onPressed: line.hasPendingAdditions ||
                                            (showNewItemHighlight &&
                                                line.existingQuantity > 0)
                                        ? () => removeSelectedItem(line)
                                        : null,
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
                      onPressed: !canConfirm()
                          ? null
                          : () async {
                              Navigator.of(context).pop(true);
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

  // Wait until the modal route has been removed before allowing the parent
  // page to pop. Popping both routes in the same frame can dispose inherited
  // widgets while the sheet still has registered dependents.
  if (shouldConfirm == true) {
    await onConfirm();
  }
}

Future<bool> _confirmVoidAllItems(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF153C3F),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFF2D6A2)),
                  SizedBox(width: 12),
                  Text('Void item?', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 16),
                const Text('The selected pending item will be removed.', style: TextStyle(color: Colors.white, height: 1.5)),
                const SizedBox(height: 22),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.of(
                      dialogContext,
                      rootNavigator: true,
                    ).pop(false),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('No'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: () => Navigator.of(
                      dialogContext,
                      rootNavigator: true,
                    ).pop(true),
                    style: ElevatedButton.styleFrom(backgroundColor: GlobalColors.buttonBackground, foregroundColor: Colors.white),
                    child: const Text('Yes'),
                  )),
                ]),
              ],
            ),
          ),
        ),
      ) ??
      false;
}

