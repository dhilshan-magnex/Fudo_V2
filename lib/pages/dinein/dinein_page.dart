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
    Navigator.of(context).pop(true);
  }

  void _showCart() => _showDineInCart(
        context,
        _cart,
        setState,
        _confirmOrder,
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GlobalColors.homeBackground,
    floatingActionButton: _CartButton(
      itemCount: _cartItemCount,
      onPressed: _showCart,
    ),
    body: HomeLayout(
      primaryContent: const _DineInHeader(),
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
  );
}
