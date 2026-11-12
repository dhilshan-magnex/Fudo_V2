part of '../delivery_page.dart';

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
