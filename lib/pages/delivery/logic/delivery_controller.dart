part of '../delivery_page.dart';

// Owns page state, lifecycle, and actions; layout is implemented by the view.
abstract class _DeliveryController extends State<DeliveryPage> {
  void _selectCustomer(CustomerContact customer) {
    setState(() {
      _selectedCustomer = customer;
      _nameController.text = customer.name;
      _addressController.text = customer.address;
      _areaController.text = customer.area;
    });
  }

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
}
