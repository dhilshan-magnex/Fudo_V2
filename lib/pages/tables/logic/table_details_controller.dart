part of '../table_page.dart';

abstract class _TableDetailsController extends State<_TableDetailsDialog> {
  late final TextEditingController _customerController;
  final _contactNoController = TextEditingController();
  final _customerFocusNode = FocusNode();
  late final TextEditingController _waiterController;
  final _paxController = TextEditingController(text: '1');
  final _formKey = GlobalKey<FormState>();
  CustomerContact? _contact;
  CustomerContact? _selectedSavedContact;
  late final Future<List<CustomerContact>> _savedContactsFuture;
  bool _isLookingUpContact = false;
  int _contactLookupVersion = 0;

  @override
  void initState() {
    super.initState();
    _savedContactsFuture = CustomerContact.loadAllByPhone();
    _customerController = TextEditingController();
    _contactNoController.addListener(_lookupContact);
    _waiterController = TextEditingController(text: widget.waiterName);
  }

  @override
  void dispose() {
    _contactNoController.removeListener(_lookupContact);
    _customerController.dispose();
    _contactNoController.dispose();
    _customerFocusNode.dispose();
    _waiterController.dispose();
    _paxController.dispose();
    super.dispose();
  }

  Future<void> _lookupContact() async {
    final phone = _contactNoController.text.trim();
    final version = ++_contactLookupVersion;
    if (phone.isEmpty) {
      if (mounted) {
        setState(() {
          _contact = null;
          _selectedSavedContact = null;
          _isLookingUpContact = false;
        });
      }
      return;
    }

    setState(() {
      if (_selectedSavedContact?.phone != phone) {
        _selectedSavedContact = null;
      }
      _isLookingUpContact = true;
    });
    final contact = await CustomerContact.findByPhone(phone);
    if (!mounted || version != _contactLookupVersion) return;
    setState(() {
      _contact = contact;
      _isLookingUpContact = false;
      if (contact != null) {
        _customerController.text = contact.name;
      }
    });
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;

    // Run a final lookup so a fast confirm cannot bypass the async lookup.
    var contact = await CustomerContact.findByPhone(
      _contactNoController.text.trim(),
    );
    if (!mounted) return;
    if (contact != null) {
      _customerController.text = contact.name;
    }
    if (contact == null) {
      contact = await showDialog<CustomerContact>(
        context: context,
        builder: (_) => ContactForm(
          initialName: _customerController.text.trim(),
          initialPhone: _contactNoController.text.trim(),
        ),
      );
      if (contact == null || !mounted) return;
      _customerController.text = contact.name;
      _contactNoController.text = contact.phone;
    }

    if (!mounted) return;
    Navigator.of(context).pop(
      _TableOrderDetails(
        customerName: contact.name,
        waiterName: _waiterController.text.trim(),
        pax: int.parse(_paxController.text.trim()),
      ),
    );
  }
}
