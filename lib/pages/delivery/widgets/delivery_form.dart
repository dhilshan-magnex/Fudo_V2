part of '../delivery_page.dart';

class _DeliveryPageState extends _DeliveryController {
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
          onSelected: _selectCustomer,
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
