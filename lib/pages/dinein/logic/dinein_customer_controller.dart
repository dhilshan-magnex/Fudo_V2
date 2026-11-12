part of '../dinein_page.dart';

abstract class _DineInCustomerController extends State<_DineInCustomerDialog> {
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
}
