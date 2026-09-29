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
        final isMobile = constraints.maxWidth < 700;
        final columnCount = isMobile ? 2 : 4;
        final gap = 13.0;
        final availableWidth = constraints.maxWidth;
        final totalGap = gap * (columnCount - 1);
        final itemWidth = (availableWidth - totalGap) / columnCount;

        final sizedButtons = buttons
            .map((button) => SizedBox(width: itemWidth, child: button))
            .toList();

        if (wrapButtons) {
          return Wrap(
            spacing: gap,
            runSpacing: gap,
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
  
//Button Design
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1200;

    return SizedBox(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: isDesktop ? 28 : GlobalColors.buttonIconSize,
        ),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: GlobalColors.buttonForeground(
            GlobalColors.buttonBackground,
          ),
          backgroundColor: GlobalColors.buttonBackground,
          minimumSize: Size.fromHeight(isDesktop ? 68 : 56),
          padding: EdgeInsets.symmetric(
            vertical: isDesktop ? 16 : 12,
            horizontal: 12,
          ),
          alignment: Alignment.centerLeft,
          textStyle: TextStyle(
            fontSize: isDesktop ? 16 : GlobalColors.buttonTextStyle.fontSize,
            fontWeight: GlobalColors.buttonTextStyle.fontWeight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: GlobalColors.divider, width: 1),
          ),
        ),
      ),
    );
  }
}
