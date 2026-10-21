import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fudo_v2/core/session/running_orders_store.dart';
import 'package:fudo_v2/core/theme/global_colors.dart';
import 'package:fudo_v2/data/database/db_manager.dart';
import 'package:fudo_v2/shared/layout/layout.dart';
import 'package:fudo_v2/shared/widgets/buttons/back_button.dart';
import 'package:fudo_v2/shared/widgets/buttons/discard_button.dart';
import 'package:fudo_v2/shared/widgets/contact_form.dart';

/// Menu browser used when creating an order or adding items to an existing one.

part 'dinein_header.dart';
part 'dinein_searchbar.dart';
part 'dinein_menu.dart';
part 'dinein_add_to_cart.dart';
part 'dinein_add_note.dart';

class DineInPage extends StatefulWidget {
  const DineInPage({
    super.key,
    this.tableNumber,
    this.customerName,
    this.customer,
    this.orderType,
    this.customerPhone,
    this.deliveryAddress,
    this.deliveryArea,
    this.orderNote,
    this.waiterName,
    this.pax,
    this.orderToUpdate,
  });

  final String? tableNumber;
  final String? customerName;
  final CustomerContact? customer;
  final String? orderType;
  final String? customerPhone;
  final String? deliveryAddress;
  final String? deliveryArea;
  final String? orderNote;
  final String? waiterName;
  final int? pax;
  final ConfirmedOrder? orderToUpdate;

  @override
  State<DineInPage> createState() => _DineInPageState();
}

class _DineInPageState extends State<DineInPage> {
  late Future<_DineInData> _menuFuture;
  final _searchController = TextEditingController();
  final _menuScrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};
  String? _categoryCode;
  String _query = '';
  final Map<String, _CartLine> _cart = {};
  bool _isLeavingPage = false;
  bool _isCollectingInitialCustomer = false;
  CustomerContact? _customer;

  int get _cartItemCount => _cart.values.fold(
    0,
    (total, line) =>
        total +
        (widget.orderToUpdate == null ? line.quantity : line.pendingQuantity),
  );

  bool get _hasPendingItems =>
      _cart.values.any((line) => line.quantity > line.existingQuantity);

  @override
  void initState() {
    super.initState();
    final order = widget.orderToUpdate;
    if (order != null) {
      for (final item in order.items) {
        final current = _cart[item.id];
        final quantity = (current?.quantity ?? 0) + item.quantity;
        final existingQuantity =
            (current?.existingQuantity ?? 0) + item.quantity;
        _cart[item.id] = _CartLine(
          DineInMenuItem(
            id: item.id,
            name: item.name,
            longName: item.name,
            categoryCode: '',
            price: item.unitPrice,
            colorCode: '',
            order: 0,
            isAvailableForDineIn: true,
          ),
          quantity,
          note: item.note,
          existingQuantity: existingQuantity,
        );
      }
    }
    _customer = widget.customer;
    _isCollectingInitialCustomer =
        order == null && widget.tableNumber == null && widget.customer == null;
    _menuFuture = _loadMenu();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    if (_isCollectingInitialCustomer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _collectInitialCustomer();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _menuScrollController.dispose();
    super.dispose();
  }

  void _jumpToCategory(String? code) {
    setState(() => _categoryCode = code);
    if (code == null) {
      if (_menuScrollController.hasClients) {
        _menuScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _categoryKeys[code]?.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          alignment: 0.05,
        );
      }
    });
  }

  Future<_DineInData> _loadMenu() async {
    final database = await DBManager.getDatabase(AppDatabase.fudo);
    final results = await Future.wait([
      database.query('Menu_Items'),
      database.query('Category_Lvl1'),
    ]);
    final categories =
        results[1]
            .map(DineInCategory.fromRow)
            .where((category) => category.code.isNotEmpty)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    final items =
        results[0]
            .map(DineInMenuItem.fromRow)
            .where((item) => item.id.isNotEmpty && item.isAvailableForDineIn)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return _DineInData(categories, items);
  }

  void _refresh() => setState(() => _menuFuture = _loadMenu());

  Future<void> _collectInitialCustomer() async {
    final customer = await showDialog<CustomerContact>(
      context: context,
      builder: (_) =>
          _DineInCustomerDialog(initialName: widget.customerName ?? ''),
    );
    if (!mounted) return;
    if (customer == null) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _customer = customer;
      _isCollectingInitialCustomer = false;
    });
  }

  void _addToCart(DineInMenuItem item) {
    setState(() {
      final line = _cart[item.id];
      final updatedLine = _CartLine(
        item,
        (line?.quantity ?? 0) + 1,
        note: line?.note ?? '',
        existingQuantity: line?.existingQuantity ?? 0,
      );
      final remainingLines = Map<String, _CartLine>.from(_cart)
        ..remove(item.id);
      _cart
        ..clear()
        ..[item.id] = updatedLine
        ..addAll(remainingLines);
    });
  }

  Future<void> _editItemNote(_CartLine line) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) =>
          _ItemNoteDialog(itemName: line.item.name, initialNote: line.note),
    );
    if (note == null || !mounted) return;

    setState(() {
      final currentLine = _cart[line.item.id];
      if (currentLine != null) {
        _cart[line.item.id] = _CartLine(
          currentLine.item,
          currentLine.quantity,
          note: note,
          existingQuantity: currentLine.existingQuantity,
        );
      }
    });
  }

  Future<void> _confirmOrder() async {
    if (!_hasPendingItems) return;

    var customer = _customer;
    if (widget.orderToUpdate == null &&
        widget.tableNumber == null &&
        customer == null) {
      customer = await showDialog<CustomerContact>(
        context: context,
        builder: (_) =>
            _DineInCustomerDialog(initialName: widget.customerName ?? ''),
      );
      if (customer == null || !mounted) return;
    }

    final items = _cart.values
        .where((line) => line.quantity > line.existingQuantity)
        .map(
          (line) => ConfirmedOrderItem(
            id: line.item.id,
            name: line.item.name,
            quantity: line.quantity - line.existingQuantity,
            unitPrice: line.item.price,
            note: line.note,
          ),
        )
        .toList();
    final store = context.read<RunningOrdersStore>();
    if (widget.orderToUpdate case final order?) {
      store.addItems(order.billId, items);
    } else {
      store.addOrder(
        items: items,
        tableNumber: widget.tableNumber,
        customerName: customer?.name ?? widget.customerName,
        customerPhone: widget.customerPhone ?? customer?.phone,
        deliveryAddress: widget.deliveryAddress ?? customer?.address,
        deliveryArea: widget.deliveryArea,
        orderNote: widget.orderNote,
        orderType: widget.orderType,
        waiterName: widget.waiterName,
        pax: widget.pax,
      );
    }
    setState(() => _isLeavingPage = true);
    Navigator.of(context).pop(true);
  }

  void _showCart() => _showDineInCart(
    context,
    _cart,
    setState,
    _confirmOrder,
    widget.orderToUpdate == null ? 'Confirm order' : 'Add items to order',
    _editItemNote,
    () => _hasPendingItems,
    widget.orderToUpdate != null,
  );

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

  void _attemptLeave() {
    if (_hasPendingItems) {
      _showPendingOrderMessage();
      return;
    }
    Navigator.of(context).maybePop();
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
              canConfirm: _hasPendingItems,
              showNewItemHighlight: widget.orderToUpdate != null,
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
              final visibleItems = data.items.where((item) {
                final matchesSearch =
                    _query.isEmpty ||
                    item.name.toLowerCase().contains(_query) ||
                    item.longName.toLowerCase().contains(_query);
                return matchesSearch;
              }).toList();
              return _MenuContent(
                categories: data.categories,
                items: visibleItems,
                selectedCategory: _categoryCode,
                searchController: _searchController,
                onCategoryChanged: _jumpToCategory,
                onRefresh: _refresh,
                scrollController: _menuScrollController,
                categoryKeys: _categoryKeys,
                onAddToCart: _addToCart,
              );
            },
          ),
        ),
      ),
    );
  }
}
