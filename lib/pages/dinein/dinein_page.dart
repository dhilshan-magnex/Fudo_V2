import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../database/db_manager.dart';
import '../../layout/layout.dart';
import '../../session/running_orders_store.dart';
import '../../utils/global_colors.dart';
import '../../widgets/buttons/back_button.dart';

/// Menu browser used when a dine-in order is being created.

part 'dinein_header.dart';
part 'dinein_searchbar.dart';
part 'dinein_menu.dart';
part 'dinein_add_to_cart.dart';

class DineInPage extends StatefulWidget {
  const DineInPage({
    super.key,
    this.tableNumber,
    this.customerName,
    this.waiterName,
    this.pax,
  });

  final String? tableNumber;
  final String? customerName;
  final String? waiterName;
  final int? pax;

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
  bool _isConfirmingOrder = false;

  int get _cartItemCount =>
      _cart.values.fold(0, (total, line) => total + line.quantity);

  @override
  void initState() {
    super.initState();
    _menuFuture = _loadMenu();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
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

  void _addToCart(DineInMenuItem item) {
    setState(() {
      final line = _cart[item.id];
      _cart[item.id] = _CartLine(item, (line?.quantity ?? 0) + 1);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${item.name} added to cart')));
  }

  void _confirmOrder() {
    if (_cart.isEmpty) return;

    final items = _cart.values
        .map((line) => ConfirmedOrderItem(
              id: line.item.id,
              name: line.item.name,
              quantity: line.quantity,
              unitPrice: line.item.price,
            ))
        .toList();
    context.read<RunningOrdersStore>().addOrder(
          items: items,
          tableNumber: widget.tableNumber,
          customerName: widget.customerName,
          waiterName: widget.waiterName,
          pax: widget.pax,
        );
    setState(() => _isConfirmingOrder = true);
    Navigator.of(context).pop(true);
  }

  void _showCart() => _showDineInCart(
        context,
        _cart,
        setState,
        _confirmOrder,
      );

  Future<void> _showPendingOrderMessage() async {
    if (!mounted) return;

    await showDialog<void>(
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
                  child: const Text(
                    'Confirm the order or remove all cart items before leaving.',
                    style: TextStyle(color: Colors.white, height: 1.5),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFAFBFC4)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _showCart();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalColors.buttonBackground,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('View cart'),
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
  }

  void _attemptLeave() {
    if (_cart.isNotEmpty) {
      _showPendingOrderMessage();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = AppLayoutType.fromContext(context).isTablet;

    return PopScope(
      canPop: _cart.isEmpty || _isConfirmingOrder,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _cart.isNotEmpty) {
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
