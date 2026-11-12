part of '../dinein_page.dart';

class _DineInPageState extends _DineInController {
  @override
  Future<String?> _quantityChangeReason() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF153C3F),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: Color(0xFFF2D6A2)),
                    SizedBox(width: 12),
                    Text(
                      'Reason for quantity change',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  autofocus: false,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter the reason',
                    hintStyle: TextStyle(color: Color(0xFFB8C7C8)),
                    filled: true,
                    fillColor: Color(0x1FFFFFFF),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(
                          dialogContext,
                          rootNavigator: true,
                        ).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final enteredReason = controller.text.trim();
                          if (enteredReason.isEmpty) return;
                          Navigator.of(
                            dialogContext,
                            rootNavigator: true,
                          ).pop(enteredReason);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalColors.buttonBackground,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await _settleOverlayTransition();
    controller.dispose();
    return reason;
  }

  @override
  Future<void> _showPendingOrderMessage() async {
    if (!mounted) return;

    final discardPendingItems = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF153C3F),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      color: Color(0xFFF2D6A2),
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Pending order',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    widget.orderToUpdate == null
                        ? 'Confirm the order to save it.'
                        : 'Confirm to add these items to ${widget.orderToUpdate!.billId}.',
                    style: const TextStyle(color: Colors.white, height: 1.5),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await _settleOverlayTransition();
                          if (!mounted) return;
                          await _confirmOrder();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalColors.buttonBackground,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          widget.orderToUpdate == null
                              ? 'Confirm order'
                              : 'Add items',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DiscardButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (discardPendingItems == true && mounted) {
      setState(() => _isLeavingPage = true);
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = AppLayoutType.fromContext(context).isTablet;

    if (_isCollectingInitialCustomer) {
      return Scaffold(
        backgroundColor: GlobalColors.homeBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: !_hasPendingItems || _isLeavingPage,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _hasPendingItems) {
          _showPendingOrderMessage();
        }
      },
      child: Scaffold(
        backgroundColor: GlobalColors.homeBackground,
        floatingActionButton: isTablet
            ? null
            : _CartButton(itemCount: _cartItemCount, onPressed: _showCart),
        body: HomeLayout(
          primaryContent: _DineInHeader(
            onBack: _attemptLeave,
            cartPage: _DineInCartPage(
              cart: _cart,
              updatePage: setState,
              onConfirm: _confirmOrder,
              onEditNote: _editItemNote,
              canConfirm: () =>
                  _hasPendingItems || widget.orderToUpdate != null,
              showNewItemHighlight: widget.orderToUpdate != null,
              canEditExistingItems: _editingExistingItems,
              onEnableExistingItemEdits: () =>
                  setState(() => _editingExistingItems = true),
              onConfirmExistingQuantity: _confirmExistingQuantity,
              confirmLabel: widget.orderToUpdate == null
                  ? 'Confirm order'
                  : 'Add items to order',
            ),
          ),
          sideContent: FutureBuilder<_DineInData>(
            future: _menuFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _MenuError(onRetry: _refresh);
              }
              final data = snapshot.data!;
              final visibleItems = _visibleItems(data);
              return _MenuContent(
                categories: data.categories,
                items: visibleItems,
                selectedCategory: _categoryCode,
                searchController: _searchController,
                onCategoryChanged: _jumpToCategory,
                onRefresh: _refresh,
                scrollController: _menuScrollController,
                onAddToCart: _addToCart,
              );
            },
          ),
        ),
      ),
    );
  }
}
