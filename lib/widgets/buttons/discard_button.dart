import 'package:flutter/material.dart';

class DiscardButton extends StatelessWidget {
  const DiscardButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFFD32F2F),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
    child: const Text('Discard'),
  );
}
