part of '../table_page.dart';

class _TableDetailsDialog extends StatefulWidget {
  const _TableDetailsDialog({required this.table, required this.waiterName});

  final TableLayoutTable table;
  final String waiterName;

  @override
  State<_TableDetailsDialog> createState() => _TableDetailsDialogState();
}

class _TableDetailsDialogState extends _TableDetailsController {
  Widget _buildCustomerNumberField() => FutureBuilder<List<CustomerContact>>(
    future: _savedContactsFuture,
    builder: (context, snapshot) => LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RawAutocomplete<CustomerContact>(
            textEditingController: _contactNoController,
            focusNode: _customerFocusNode,
            displayStringForOption: (contact) => contact.phone,
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              final contacts = snapshot.data;
              if (query.isEmpty ||
                  contacts == null ||
                  _selectedSavedContact?.phone == query) {
                return const <CustomerContact>[];
              }
              return contacts
                  .where((contact) => contact.phone.contains(query))
                  .take(8);
            },
            onSelected: (contact) {
              setState(() {
                _selectedSavedContact = contact;
                _contact = contact;
                _isLookingUpContact = false;
                _customerController.text = contact.name;
                _contactNoController.text = contact.phone;
              });
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) =>
                    _DialogField(
                      controller: controller,
                      focusNode: focusNode,
                      label: 'Contact number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a contact number'
                          : null,
                    ),
            optionsViewBuilder: (context, onSelected, options) {
              final matches = options.toList();
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: matches.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final contact = matches[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.person_outline,
                              color: GlobalColors.homeActionBackground,
                            ),
                            title: Text(contact.phone),
                            subtitle: contact.name.isEmpty
                                ? null
                                : Text(contact.name),
                            onTap: () => onSelected(contact),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (snapshot.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Could not load saved contacts.',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
        ],
      ),
    ),
  );

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
          maxHeight: (screenHeight - 48).clamp(240.0, screenHeight * 0.9),
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
                          Icons.table_restaurant_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Table ${widget.table.number}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'Enter order details to continue',
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
                        // This dialog returns _TableOrderDetails on confirm;
                        // dismissal should return null, not a bool.
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _buildCustomerNumberField(),
                  if (_contactNoController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ContactLookupStatus(
                      contact: _contact,
                      isLoading: _isLookingUpContact,
                    ),
                  ],
                  const SizedBox(height: 14),
                  _DialogField(
                    controller: _customerController,
                    label: 'Customer name',
                    icon: Icons.person_outline,
                    capitalization: TextCapitalization.words,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a customer name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _DialogField(
                    controller: _waiterController,
                    label: 'Waiter',
                    icon: Icons.badge_outlined,
                    capitalization: TextCapitalization.words,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a waiter name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _DialogField(
                    controller: _paxController,
                    label: 'Pax',
                    icon: Icons.groups_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final pax = int.tryParse(value?.trim() ?? '');
                      return pax == null || pax < 1
                          ? 'Enter at least 1 guest'
                          : null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _DialogAction(
                          label: 'Back',
                          icon: Icons.arrow_back_rounded,
                          outlined: true,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DialogAction(
                          label: 'Confirm',
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
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    required this.icon,
    this.focusNode,
    this.capitalization = TextCapitalization.none,
    this.keyboardType,
    this.validator,
  }) : maxLines = 1,
       readOnly = false,
       onTap = null;

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FocusNode? focusNode;
  final TextCapitalization capitalization;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

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
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
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

class _DialogAction extends StatelessWidget {
  const _DialogAction({
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
