import 'package:flutter/material.dart';
import '../utils/global_colors.dart';

class HomeActionPanel extends StatelessWidget {
  const HomeActionPanel({
    super.key,
    required this.wrapButtons,
    required this.buttons,
  });

  final bool wrapButtons;
  final List<HomeActionButton> buttons;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth = wrapButtons
            ? (constraints.maxWidth - 15) / 2
            : constraints.maxWidth;
        final sizedButtons = buttons
            .map(
              (button) => SizedBox(
                width: buttonWidth,
                child: button,
              ),
            )
            .toList();

        if (wrapButtons) {
          return Wrap(
            spacing: 14,
            runSpacing: 12,
            alignment: WrapAlignment.start,
            children: sizedButtons,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: sizedButtons,
        );
      },
    );
  }
}

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
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: GlobalColors.buttonIconSize),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: GlobalColors.buttonText,
          backgroundColor: GlobalColors.buttonBackground,
          minimumSize: GlobalColors.buttonMinimumSize,
          padding: GlobalColors.buttonPadding,
          alignment: Alignment.centerLeft,
          textStyle: GlobalColors.buttonTextStyle,
        ),
      ),
    );
  }
}