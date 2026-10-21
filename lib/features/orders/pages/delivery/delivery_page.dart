import 'package:flutter/material.dart';

import 'package:fudo_v2/core/theme/global_colors.dart';
import 'package:fudo_v2/features/orders/pages/dinein/dinein_page.dart';
import 'package:fudo_v2/shared/layout/layout.dart';
import 'package:fudo_v2/shared/widgets/buttons/back_button.dart';
import 'package:fudo_v2/shared/widgets/contact_form.dart';

part 'delivery_header.dart';

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();
  final _noteController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  late final Future<List<CustomerContact>> _customersFuture;
  late final Future<List<String>> _areasFuture;
  CustomerContact? _selectedCustomer;
  bool _isOpeningDineIn = false;

  @override
  void initState() {
    super.initState();
    _customersFuture = CustomerContact.loadAllByPhone();
    _areasFuture = CustomerContact.loadAreas();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _noteController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _continueToDineIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isOpeningDineIn = true);
    var customer = CustomerContact(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      dateOfBirth: '',
      anniversary: '',
      area: _areaController.text.trim(),
    );
    try {
      customer = await customer.save();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isOpeningDineIn = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save customer details. Please try again.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    final orderConfirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => DineInPage(
          customer: customer,
          orderType: 'Delivery',
          customerPhone: customer.phone,
          deliveryAddress: customer.address,
          deliveryArea: customer.area,
          orderNote: _noteController.text.trim(),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _isOpeningDineIn = false);
    if (orderConfirmed == true) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GlobalColors.homeBackground,
    body: HomeLayout(
      primaryContent: const _DeliveryHeader(),
      sideContent: _buildDeliveryContent(context),
    ),
  );

  Widget _buildDeliveryContent(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 500;
      return SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Container(
              padding: EdgeInsets.all(compact ? 20 : 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: GlobalColors.billingCardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Customer details',
                    style: TextStyle(
                      color: GlobalColors.primaryText,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter delivery information before selecting items.',
                    style: TextStyle(color: GlobalColors.secondaryText),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailsContent(),
                  const SizedBox(height: 28),
                  _buildActions(compact),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _buildDetailsContent() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLabel('PHONE NUMBER'),
                const SizedBox(height: 8),
                _buildPhoneField(constraints.maxWidth),
                const SizedBox(height: 16),
                _buildLabel('CUSTOMER NAME'),
                const SizedBox(height: 8),
                _DeliveryField(
                  controller: _nameController,
                  hint: 'Enter customer name',
                  capitalization: TextCapitalization.words,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a customer name'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildLabel('DELIVERY ADDRESS'),
                const SizedBox(height: 8),
                _DeliveryField(
                  controller: _addressController,
                  hint: 'Enter delivery address',
                  capitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 3,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a delivery address'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildLabel('AREA'),
                const SizedBox(height: 8),
                _buildAreaField(),
                const SizedBox(height: 16),
                // _buildLabel('ORDER NOTE'),
                // const SizedBox(height: 8),
                // _DeliveryField(
                //   controller: _noteController,
                //   hint: 'e.g. call on arrival',
                //   capitalization: TextCapitalization.sentences,
                //   minLines: 1,
                //   maxLines: 3,
                // ),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _buildPhoneField(double availableWidth) =>
      FutureBuilder<List<CustomerContact>>(
        future: _customersFuture,
        builder: (context, snapshot) => RawAutocomplete<CustomerContact>(
          textEditingController: _phoneController,
          focusNode: _phoneFocusNode,
          displayStringForOption: (customer) => customer.phone,
          optionsBuilder: (value) {
            final query = value.text.trim().toLowerCase();
            final customers = snapshot.data;
            if (query.isEmpty ||
                customers == null ||
                _selectedCustomer?.phone.toLowerCase() == query) {
              return const <CustomerContact>[];
            }
            return customers
                .where(
                  (customer) => customer.phone.toLowerCase().contains(query),
                )
                .take(8);
          },
          onSelected: (customer) {
            setState(() {
              _selectedCustomer = customer;
              _nameController.text = customer.name;
              _addressController.text = customer.address;
              _areaController.text = customer.area;
            });
          },
          fieldViewBuilder: (context, controller, focusNode, _) =>
              _DeliveryField(
                controller: controller,
                focusNode: focusNode,
                hint: 'Enter phone number',
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a phone number'
                    : null,
              ),
          optionsViewBuilder: (context, onSelected, options) {
            final matches = options.toList();
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.white,
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: (availableWidth - 84).clamp(180.0, 900.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: matches.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final customer = matches[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.person_outline,
                            color: GlobalColors.homeActionBackground,
                          ),
                          title: Text(customer.phone),
                          subtitle: customer.name.isEmpty
                              ? null
                              : Text(customer.name),
                          onTap: () => onSelected(customer),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _buildAreaField() => FutureBuilder<List<String>>(
    future: _areasFuture,
    builder: (context, snapshot) {
      final areas = snapshot.data ?? const <String>[];
      if (areas.isEmpty) {
        return _DeliveryField(
          controller: _areaController,
          hint: 'Enter area',
          capitalization: TextCapitalization.words,
        );
      }

      final selectedArea = areas.contains(_areaController.text)
          ? _areaController.text
          : null;
      return DropdownButtonFormField<String>(
        key: ValueKey(selectedArea),
        initialValue: selectedArea,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        decoration: _fieldDecoration('Select area'),
        style: const TextStyle(color: GlobalColors.primaryText, fontSize: 17),
        items: areas
            .map((area) => DropdownMenuItem(value: area, child: Text(area)))
            .toList(),
        onChanged: (area) {
          if (area == null) return;
          setState(() => _areaController.text = area);
        },
      );
    },
  );

  Widget _buildLabel(String label) => Text(
    label,
    style: const TextStyle(
      color: GlobalColors.billingHeaderText,
      fontSize: 13,
      fontWeight: FontWeight.w800,
    ),
  );

  Widget _buildActions(bool compact) => Row(
    children: [
      Expanded(
        flex: compact ? 4 : 3,
        child: SizedBox(
          height: 60,
          child: OutlinedButton(
            onPressed: _isOpeningDineIn
                ? null
                : () => Navigator.of(context).maybePop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: GlobalColors.primaryText,
              side: const BorderSide(color: GlobalColors.billingOutline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        flex: compact ? 7 : 5,
        child: SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: _isOpeningDineIn ? null : _continueToDineIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalColors.homeActionBackground,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isOpeningDineIn
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Continue to Order'),
          ),
        ),
      ),
    ],
  );
}

class _DeliveryField extends StatelessWidget {
  const _DeliveryField({
    required this.controller,
    required this.hint,
    this.focusNode,
    this.capitalization = TextCapitalization.none,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final TextCapitalization capitalization;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    focusNode: focusNode,
    textCapitalization: capitalization,
    keyboardType: keyboardType,
    minLines: minLines,
    maxLines: maxLines,
    validator: validator,
    style: const TextStyle(color: GlobalColors.primaryText, fontSize: 17),
    decoration: _fieldDecoration(hint),
  );
}

InputDecoration _fieldDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: GlobalColors.billingChevron),
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: GlobalColors.billingOutline),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: GlobalColors.billingOutline),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: GlobalColors.homeActionBackground),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: Colors.redAccent),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: Colors.redAccent),
  ),
);
