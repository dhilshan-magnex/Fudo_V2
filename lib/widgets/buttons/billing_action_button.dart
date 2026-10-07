import 'package:flutter/material.dart';
import '../../utils/global_colors.dart';
import 'app_button.dart';

/// A compact, icon-led action button for order-flow screens.
class BillingActionButton extends StatelessWidget {
  const BillingActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 150;
          return AppButton(
            label: label,
            icon: icon,
            onPressed: onPressed,
            variant: outlined ? AppButtonVariant.outlined : AppButtonVariant.filled,
            backgroundColor: outlined ? AppPalette.white : null,
            padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 16),
            borderRadius: 27,
            iconSize: compact ? 18 : 28,
            fontSize: compact ? 14 : 25,
          );
        },
      );
}
