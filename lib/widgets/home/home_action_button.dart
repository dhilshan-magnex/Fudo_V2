import 'package:flutter/material.dart';

class HomeActionButton extends StatelessWidget {
  const HomeActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: Colors.black87,
          backgroundColor: const Color.fromARGB(255, 128, 148, 158),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
