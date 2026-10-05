import 'package:flutter/material.dart';

import 'button.dart';
import '../utils/global_colors.dart';

/// A shared Back action that returns to the previous route by default.
class FudoBackButton extends StatelessWidget {
  const FudoBackButton({
    super.key,
    this.onPressed,
    this.label = 'Back',
    this.mode = HomeActionButtonMode.compact,
    this.backgroundColor = GlobalColors.homeActionBackground,
  });

  final VoidCallback? onPressed;
  final String label;
  final HomeActionButtonMode mode;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => HomeActionButton(
        icon: Icons.arrow_back_rounded,
        label: label,
        mode: mode,
        backgroundColor: backgroundColor,
        onTap: onPressed ?? () => Navigator.maybePop(context),
      );
}
