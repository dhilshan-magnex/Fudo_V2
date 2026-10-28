part of '../dinein_page.dart';

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
  final _phoneFocusNode = FocusNode();
  late final Future<List<CustomerContact>> _contactsFuture;
  CustomerContact? _selectedContact;
  bool _isLookingUp = false;
  int _lookupVersion = 0;

  @override
  void initState() {
    super.initState();
    _contactsFuture = CustomerContact.loadAllByPhone();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController.addListener(_lookupContact);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_lookupContact);
    _nameController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _lookupContact() async {
    final phone = _phoneController.text.trim();
    final version = ++_lookupVersion;
    if (phone.isEmpty) {
      if (!mounted) return;
      setState(() {
        _selectedContact = null;
        _isLookingUp = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      if (_selectedContact?.phone != phone) {
        _selectedContact = null;
      }
      _isLookingUp = true;
    });
    final contact = await CustomerContact.findByPhone(phone);
    if (!mounted || version != _lookupVersion) return;
    setState(() {
      _selectedContact = contact;
      _isLookingUp = false;
      if (contact != null) _nameController.text = contact.name;
    });
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    var contact = await CustomerContact.findByPhone(
      _phoneController.text.trim(),
    );
    if (!mounted) return;
    if (contact == null) {
      contact = await showDialog<CustomerContact>(
        context: context,
        builder: (_) => ContactForm(
          initialName: name,
          initialPhone: _phoneController.text.trim(),
        ),
      );
      await _settleOverlayTransition();
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
                  _buildCustomerNumberField(),
                  const SizedBox(height: 14),
                  _DineInCustomerField(
                    controller: _nameController,
                    label: 'Customer name',
                    icon: Icons.person_outline,
                    capitalization: TextCapitalization.words,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a customer name'
                        : null,
                  ),
                  const SizedBox(height: 14),
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

  Widget _buildCustomerNumberField() => FutureBuilder<List<CustomerContact>>(
    future: _contactsFuture,
    builder: (context, snapshot) => RawAutocomplete<CustomerContact>(
      textEditingController: _phoneController,
      focusNode: _phoneFocusNode,
      displayStringForOption: (contact) => contact.phone,
      optionsBuilder: (value) {
        final query = value.text.trim();
        if (query.isEmpty || snapshot.data == null) {
          return const <CustomerContact>[];
        }
        return snapshot.data!
            .where((contact) => contact.phone.contains(query))
            .take(8);
      },
      onSelected: (contact) {
        setState(() {
          _selectedContact = contact;
          _nameController.text = contact.name;
        });
      },
      fieldViewBuilder: (context, controller, focusNode, _) =>
          _DineInCustomerField(
            controller: controller,
            focusNode: focusNode,
            label: 'Customer number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
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
                      title: Text(contact.phone),
                      subtitle: Text(contact.name),
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
