import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/db_manager.dart';
import '../layout/layout.dart';
import '../utils/global_colors.dart';

/// A customer contact stored in the local customer master.
class CustomerContact {
  const CustomerContact({
    required this.name,
    required this.address,
    required this.phone,
    required this.dateOfBirth,
    required this.anniversary,
  });

  final String name;
  final String address;
  final String phone;
  final String dateOfBirth;
  final String anniversary;

  factory CustomerContact.fromRow(Map<String, dynamic> row) => CustomerContact(
    name: row['Customer_Name']?.toString().trim() ?? '',
    address: row['Customer_Address']?.toString().trim() ?? '',
    phone: row['Customer_Phone']?.toString().trim() ?? '',
    dateOfBirth: row['Customer_DoB']?.toString().trim() ?? '',
    anniversary: row['Customer_Anniversary']?.toString().trim() ?? '',
  );

  static Future<CustomerContact?> findByName(String name) async {
    final database = await DBManager.getDatabase(AppDatabase.fudo);
    final rows = await database.query('Customer_Master', where: 'LOWER(TRIM(Customer_Name)) = LOWER(?)', whereArgs: [name.trim()], limit: 1);
    return rows.isEmpty ? null : CustomerContact.fromRow(rows.first);
  }

  static Future<List<CustomerContact>> loadAll() async {
    final database = await DBManager.getDatabase(AppDatabase.fudo);
    final rows = await database.query('Customer_Master', orderBy: 'Customer_Name COLLATE NOCASE');
    final seenNames = <String>{};
    return rows.map(CustomerContact.fromRow).where((contact) => contact.name.isNotEmpty && seenNames.add(contact.name.toLowerCase())).toList();
  }

  Future<CustomerContact> save() async {
    final database = await DBManager.getDatabase(AppDatabase.fudo);
    final existing = await findByName(name);
    if (existing != null) return existing;
    await _ensureAdditionalInfoColumns(database);
    await database.insert('Customer_Master', {
      'Customer_Code': 'LOCAL-${DateTime.now().microsecondsSinceEpoch}', 'Customer_Name': name, 'Customer_Address': address, 'Customer_Phone': phone, 'Customer_Email': '', 'Customer_Cr_Limit': 0, 'Customer_Cur_Bal': 0, 'Customer_Group': '', 'Customer_Active': 1, 'Customer_DoB': dateOfBirth, 'Customer_Anniversary': anniversary,
    });
    return this;
  }

  static Future<void> _ensureAdditionalInfoColumns(Database database) async {
    final names = (await database.rawQuery('PRAGMA table_info(Customer_Master)')).map((column) => column['name']?.toString()).whereType<String>().toSet();
    if (!names.contains('Customer_DoB')) await database.execute('ALTER TABLE Customer_Master ADD COLUMN Customer_DoB TEXT');
    if (!names.contains('Customer_Anniversary')) await database.execute('ALTER TABLE Customer_Master ADD COLUMN Customer_Anniversary TEXT');
  }
}

/// Displays whether a customer-name lookup found an existing contact.
class ContactLookupStatus extends StatelessWidget {
  const ContactLookupStatus({
    super.key,
    required this.contact,
    required this.isLoading,
  });

  final CustomerContact? contact;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final found = contact != null;
    return Row(
      children: [
        if (isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(
            found ? Icons.check_circle_outline : Icons.person_add_alt_1_outlined,
            size: 18,
            color: found ? const Color(0xFFB7E4C7) : GlobalColors.homeHeaderLabel,
          ),
        const SizedBox(width: 8),
        Text(
          isLoading
              ? 'Looking up contact...'
              : found
              ? 'Existing contact found${contact!.phone.isEmpty ? '' : ' - ${contact!.phone}'}'
              : 'New contact - details will be requested next',
          style: const TextStyle(
            color: GlobalColors.homeHeaderLabel,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// A reusable dialog for creating a customer contact. Pops with the saved contact.
class ContactForm extends StatefulWidget {
  const ContactForm({super.key, this.initialName = ''});

  final String initialName;

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _anniversaryController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() { super.initState(); _nameController = TextEditingController(text: widget.initialName); }

  @override
  void dispose() { _nameController.dispose(); _addressController.dispose(); _phoneController.dispose(); _dateOfBirthController.dispose(); _anniversaryController.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final contact = await CustomerContact(name: _nameController.text.trim(), address: _addressController.text.trim(), phone: _phoneController.text.trim(), dateOfBirth: _dateOfBirthController.text.trim(), anniversary: _anniversaryController.text.trim()).save();
      if (mounted) Navigator.of(context).pop(contact);
    } catch (_) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save the contact. Please try again.'))); setState(() => _isSaving = false); }
    }
  }

  Future<void> _pickDate(TextEditingController controller, String title) async {
    final date = await showDatePicker(context: context, helpText: title, initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now());
    if (date != null && mounted) setState(() => controller.text = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppLayoutType.fromContext(context).isMobile;
    return Dialog(backgroundColor: Colors.transparent, elevation: 0, insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24), child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 420, maxHeight: 600), child: Container(padding: EdgeInsets.all(isMobile ? 20 : 24), decoration: BoxDecoration(color: GlobalColors.homeHeaderBackground, borderRadius: BorderRadius.circular(24)), child: SingleChildScrollView(child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [const Icon(Icons.person_add_alt_1_outlined, color: Colors.white), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('New contact', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)), Text('Save customer details to continue', style: TextStyle(color: GlobalColors.homeHeaderLabel, fontSize: 13))])), IconButton(tooltip: 'Close', color: Colors.white, onPressed: _isSaving ? null : () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded))]),
      const SizedBox(height: 22),
      _ContactField(controller: _nameController, label: 'Name', icon: Icons.person_outline, capitalization: TextCapitalization.words, validator: (value) => value == null || value.trim().isEmpty ? 'Enter a contact name' : null),
      const SizedBox(height: 14), _ContactField(controller: _phoneController, label: 'Contact', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
      const SizedBox(height: 14), _ContactField(controller: _addressController, label: 'Address', icon: Icons.location_on_outlined, capitalization: TextCapitalization.sentences, maxLines: 2),
      const SizedBox(height: 22), const Text('Additional information', style: TextStyle(color: GlobalColors.homeHeaderLabel, fontSize: 14, fontWeight: FontWeight.w700)), const SizedBox(height: 14),
      _ContactField(controller: _dateOfBirthController, label: 'DOB', icon: Icons.cake_outlined, readOnly: true, onTap: () => _pickDate(_dateOfBirthController, 'Select date of birth')),
      const SizedBox(height: 14), _ContactField(controller: _anniversaryController, label: 'Anniversary', icon: Icons.favorite_border_rounded, readOnly: true, onTap: () => _pickDate(_anniversaryController, 'Select anniversary date')),
      const SizedBox(height: 24), Row(children: [Expanded(child: _ContactAction(label: 'Back', icon: Icons.arrow_back_rounded, outlined: true, onPressed: _isSaving ? null : () => Navigator.of(context).pop())), const SizedBox(width: 12), Expanded(child: _ContactAction(label: _isSaving ? 'Saving...' : 'Save contact', icon: _isSaving ? Icons.hourglass_top_rounded : Icons.check_rounded, onPressed: _isSaving ? null : _save))])
    ]))))));
  }
}

class _ContactField extends StatelessWidget {
  const _ContactField({required this.controller, required this.label, required this.icon, this.capitalization = TextCapitalization.none, this.keyboardType, this.validator, this.maxLines = 1, this.readOnly = false, this.onTap});
  final TextEditingController controller; final String label; final IconData icon; final TextCapitalization capitalization; final TextInputType? keyboardType; final FormFieldValidator<String>? validator; final int maxLines; final bool readOnly; final VoidCallback? onTap;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: const TextStyle(color: GlobalColors.homeHeaderLabel, fontSize: 14, fontWeight: FontWeight.w700))), TextFormField(controller: controller, textCapitalization: capitalization, keyboardType: keyboardType, maxLines: maxLines, readOnly: readOnly, onTap: onTap, validator: validator, decoration: InputDecoration(prefixIcon: Icon(icon, color: GlobalColors.homeActionBackground), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)))]);
}

class _ContactAction extends StatelessWidget {
  const _ContactAction({required this.label, required this.icon, required this.onPressed, this.outlined = false}); final String label; final IconData icon; final VoidCallback? onPressed; final bool outlined;
  @override Widget build(BuildContext context) => TextButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label), style: TextButton.styleFrom(foregroundColor: outlined ? Colors.white : GlobalColors.homeHeaderBackground, backgroundColor: outlined ? Colors.transparent : Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: outlined ? const BorderSide(color: GlobalColors.homeHeaderLabel) : BorderSide.none)));
}
