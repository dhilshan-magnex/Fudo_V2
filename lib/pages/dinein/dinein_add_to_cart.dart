part of 'dinein_page.dart';

final _cartPriceFormat = NumberFormat('#,##0.00');

void _showDineInCart(
  BuildContext context,
  Map<String, _CartLine> cart,
  void Function(VoidCallback) updatePage,
  Future<void> Function() onConfirm,
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
                          : () async {
                              Navigator.of(context).pop();
                              await onConfirm();
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
  final Future<void> Function() onConfirm;
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
                onPressed: cart.isEmpty
                    ? null
                    : () async => await onConfirm(),
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

/// Selects a saved customer, or creates one before a new dine-in order is made.
class _DineInCustomerDialog extends StatefulWidget {
  const _DineInCustomerDialog({required this.initialName});

  final String initialName;

  @override
  State<_DineInCustomerDialog> createState() => _DineInCustomerDialogState();
}

class _DineInCustomerDialogState extends State<_DineInCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _phoneController = TextEditingController();
  final _nameFocusNode = FocusNode();
  late final Future<List<CustomerContact>> _contactsFuture;
  CustomerContact? _selectedContact;
  bool _isLookingUp = false;
  int _lookupVersion = 0;

  @override
  void initState() {
    super.initState();
    _contactsFuture = CustomerContact.loadAll();
    _nameController = TextEditingController(text: widget.initialName);
    _nameController.addListener(_lookupContact);
    if (widget.initialName.trim().isNotEmpty) _lookupContact();
  }

  @override
  void dispose() {
    _nameController.removeListener(_lookupContact);
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _lookupContact() async {
    final name = _nameController.text.trim();
    final version = ++_lookupVersion;
    if (name.isEmpty) {
      if (!mounted) return;
      setState(() {
        _selectedContact = null;
        _isLookingUp = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      if (_selectedContact?.name.toLowerCase() != name.toLowerCase()) {
        _selectedContact = null;
      }
      _isLookingUp = true;
    });
    final contact = await CustomerContact.findByName(name);
    if (!mounted || version != _lookupVersion) return;
    setState(() {
      _selectedContact = contact;
      _isLookingUp = false;
      if (contact != null) _phoneController.text = contact.phone;
    });
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    var contact = await CustomerContact.findByName(name);
    if (!mounted) return;
    if (contact == null) {
      contact = await showDialog<CustomerContact>(
        context: context,
        builder: (_) => ContactForm(
          initialName: name,
          initialPhone: _phoneController.text.trim(),
        ),
      );
      if (contact == null || !mounted) return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(contact);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppLayoutType.fromContext(context).isMobile;
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: (screenHeight - 48).clamp(280.0, screenHeight * 0.9),
        ),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 20 : 24),
          decoration: BoxDecoration(
            color: GlobalColors.homeHeaderBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Select a saved customer or add a new one.',
                              style: TextStyle(
                                color: GlobalColors.homeHeaderLabel,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        color: Colors.white,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _buildCustomerField(),
                  const SizedBox(height: 14),
                  _DineInCustomerField(
                    controller: _phoneController,
                    label: 'Customer phone number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  ContactLookupStatus(
                    contact: _selectedContact,
                    isLoading: _isLookingUp,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _DineInCustomerAction(
                          label: 'Back',
                          icon: Icons.arrow_back_rounded,
                          outlined: true,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DineInCustomerAction(
                          label: 'Continue',
                          icon: Icons.check_rounded,
                          onPressed: _confirm,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerField() => FutureBuilder<List<CustomerContact>>(
    future: _contactsFuture,
    builder: (context, snapshot) => RawAutocomplete<CustomerContact>(
      textEditingController: _nameController,
      focusNode: _nameFocusNode,
      displayStringForOption: (contact) => contact.name,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty || snapshot.data == null) {
          return const <CustomerContact>[];
        }
        return snapshot.data!
            .where((contact) => contact.name.toLowerCase().contains(query))
            .take(8);
      },
      onSelected: (contact) {
        setState(() {
          _selectedContact = contact;
          _phoneController.text = contact.phone;
        });
      },
      fieldViewBuilder: (context, controller, focusNode, _) =>
          _DineInCustomerField(
            controller: controller,
            focusNode: focusNode,
            label: 'Customer name',
            icon: Icons.person_outline,
            capitalization: TextCapitalization.words,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a customer name'
                : null,
          ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: Colors.white,
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, minWidth: 300),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: options
                  .map(
                    (contact) => ListTile(
                      dense: true,
                      title: Text(contact.name),
                      subtitle: contact.phone.isEmpty
                          ? null
                          : Text(contact.phone),
                      onTap: () => onSelected(contact),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    ),
  );
}

class _DineInCustomerField extends StatelessWidget {
  const _DineInCustomerField({
    required this.controller,
    required this.label,
    required this.icon,
    this.focusNode,
    this.capitalization = TextCapitalization.none,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FocusNode? focusNode;
  final TextCapitalization capitalization;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: GlobalColors.homeHeaderLabel,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      TextFormField(
        controller: controller,
        focusNode: focusNode,
        textCapitalization: capitalization,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: GlobalColors.primaryText),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: GlobalColors.homeActionBackground),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: GlobalColors.homeStatusBackground,
              width: 2,
            ),
          ),
        ),
      ),
    ],
  );
}

class _DineInCustomerAction extends StatelessWidget {
  const _DineInCustomerAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: Icon(icon),
    label: Text(label),
    style: TextButton.styleFrom(
      foregroundColor: outlined
          ? Colors.white
          : GlobalColors.homeHeaderBackground,
      backgroundColor: outlined ? Colors.transparent : Colors.white,
      minimumSize: const Size.fromHeight(52),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: outlined
            ? const BorderSide(color: GlobalColors.homeHeaderLabel)
            : BorderSide.none,
      ),
    ),
  );
}

class _CartLine {
  const _CartLine(this.item, this.quantity, {this.note = ''});
  final DineInMenuItem item;
  final int quantity;
  final String note;
}
