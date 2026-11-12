part of '../dinein_page.dart';

// Owns page state, lifecycle, and actions; layout is implemented by the view.
abstract class _DineInController extends State<DineInPage> {
  List<DineInMenuItem> _visibleItems(_DineInData data) =>
      data.items.where((item) {
        final matchesSearch =
            _query.isEmpty ||
            item.name.toLowerCase().contains(_query) ||
            item.longName.toLowerCase().contains(_query);
        return matchesSearch;
      }).toList();

  late Future<_DineInData> _menuFuture;
  final _searchController = TextEditingController();
  final _menuScrollController = ScrollController();
  String? _categoryCode;
  String _query = '';
  final Map<String, _CartLine> _cart = {};
  bool _isLeavingPage = false;
  bool _editingExistingItems = false;
  bool _hasLoadedVoidedLines = false;
  bool _isCollectingInitialCustomer = false;
  CustomerContact? _customer;

  int get _cartItemCount => _cart.values.fold(
    0,
    (total, line) =>
        total +
        (widget.orderToUpdate == null ? line.quantity : line.pendingQuantity),
  );

  bool get _hasPendingItems => _cart.values.any(
    (line) => !line.isVoided && line.quantity > line.existingQuantity,
  );

  @override
  void initState() {
    super.initState();
    final order = widget.orderToUpdate;
    if (order != null) {
      for (final item in order.items) {
        if (item.isVoided) continue;
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
  }

  Future<_DineInData> _loadMenu() async {
    final order = widget.orderToUpdate;
    if (order != null && !_hasLoadedVoidedLines) {
      _hasLoadedVoidedLines = true;
      final rows = await context.read<OrderProvider>().getBillingItemRows(
        order.billId,
      );
      if (mounted) {
        for (final row in rows.where(
          (row) => row['Tran_Type']?.toString() == 'TV',
        )) {
          final key = 'void-${row['Line_No'] ?? _cart.length}';
          final item = DineInMenuItem(
            id: key,
            name: row['Tran_Description']?.toString() ?? '',
            longName: row['Tran_Description']?.toString() ?? '',
            categoryCode: '',
            price: (row['Unit_Price'] as num?)?.toDouble() ?? 0,
            colorCode: '',
            order: 0,
            isAvailableForDineIn: true,
          );
          _cart[key] = _CartLine(
            item,
            (row['Tran_Qty'] as num?)?.toInt() ?? 0,
            note: row['Tran_Ref']?.toString() ?? '',
            isVoided: true,
          );
        }
      }
    }
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
    await _settleOverlayTransition();
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
      if (widget.orderToUpdate != null &&
          line != null &&
          line.existingQuantity > 0) {
        return;
      }
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
    await _settleOverlayTransition();
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
    final changedExistingLines = _cart.values
        .where(
          (line) =>
              line.existingQuantity > 0 &&
              line.quantity != line.existingQuantity,
        )
        .toList();
    for (final line in changedExistingLines) {
      if (!await _confirmExistingQuantity(line)) return;
      if (!mounted) return;
      setState(() {
        _cart[line.item.id] = _CartLine(
          line.item,
          line.quantity,
          note: line.note,
          existingQuantity: line.quantity,
        );
      });
    }

    if (!_hasPendingItems) {
      if (widget.orderToUpdate != null) {
        await context.read<OrderProvider>().markBillAddItemsConfirmed(
          widget.orderToUpdate!.billId,
        );
        if (!mounted) return;
        setState(() => _isLeavingPage = true);
        Navigator.of(context).pop(true);
      }
      return;
    }

    var customer = _customer;
    if (widget.orderToUpdate == null &&
        widget.tableNumber == null &&
        customer == null) {
      customer = await showDialog<CustomerContact>(
        context: context,
        builder: (_) =>
            _DineInCustomerDialog(initialName: widget.customerName ?? ''),
      );
      await _settleOverlayTransition();
      if (customer == null || !mounted) return;
    }

    final items = _cart.values
        .where(
          (line) => !line.isVoided && line.quantity > line.existingQuantity,
        )
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
    if (widget.orderToUpdate case final order?) {
      try {
        await context.read<OrderProvider>().addItemsToOrder(
          billNo: order.billId,
          refNo: order.refNo,
          type: order.type,
          items: items
              .map(
                (item) => OrderItem(
                  id: item.id,
                  name: item.name,
                  quantity: item.quantity,
                  unitPrice: item.unitPrice,
                  note: item.note,
                ),
              )
              .toList(),
          tableNumber: order.tableNumber,
          customerName: order.customerName,
          customerPhone: order.customerPhone,
          deliveryAddress: order.deliveryAddress,
          deliveryArea: order.deliveryArea,
          orderNote: order.orderNote,
          waiterName: order.waiterName,
          pax: order.pax,
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error code: ORDER-001')));
        return;
      }
    } else {
      try {
        await context.read<OrderProvider>().createOrder(
          // The client ID is the only POS-level value currently available in
          // the session. Replace this with a terminal/Counter_No setting when
          // that configuration is added.
          posId: context.read<SessionProvider>().clientId ?? 'DEFAULT',
          type:
              widget.orderType ??
              (widget.tableNumber == null ? 'Dine In' : 'Table'),
          items: items
              .map(
                (item) => OrderItem(
                  id: item.id,
                  name: item.name,
                  quantity: item.quantity,
                  unitPrice: item.unitPrice,
                  note: item.note,
                ),
              )
              .toList(),
          tableNumber: widget.tableNumber,
          customerName: customer?.name ?? widget.customerName,
          customerPhone: widget.customerPhone ?? customer?.phone,
          deliveryAddress: widget.deliveryAddress ?? customer?.address,
          deliveryArea: widget.deliveryArea,
          orderNote: widget.orderNote,
          waiterName: widget.waiterName,
          pax: widget.pax,
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error code: ORDER-002')));
        return;
      }
    }
    if (!mounted) return;
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
    () => _hasPendingItems || widget.orderToUpdate != null,
    widget.orderToUpdate != null,
    _editingExistingItems,
    () => setState(() => _editingExistingItems = true),
    _confirmExistingQuantity,
  );

  Future<bool> _confirmExistingQuantity(_CartLine line) async {
    final order = widget.orderToUpdate;
    if (order == null) return false;
    final reason = await _quantityChangeReason();
    if (reason == null || !mounted) return false;
    final orderProvider = context.read<OrderProvider>();
    try {
      await orderProvider.updateOrderItemQuantity(
        billNo: order.billId,
        menuId: line.item.id,
        quantity: line.quantity,
        reason: reason,
      );
      if (mounted) setState(() => _editingExistingItems = false);
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error code: ORDER-003')));
      }
      return false;
    }
  }

  Future<String?> _quantityChangeReason();

  Future<void> _showPendingOrderMessage();

  void _attemptLeave() {
    if (_hasPendingItems) {
      _showPendingOrderMessage();
      return;
    }
    Navigator.of(context).maybePop();
  }
}
