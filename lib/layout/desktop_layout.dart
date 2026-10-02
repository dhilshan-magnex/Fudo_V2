import 'package:flutter/material.dart';
import '../utils/global_colors.dart';

class DesktopLayout extends StatelessWidget {
  const DesktopLayout({
    super.key,
    required this.primaryContent,
    required this.sideContent,
  });

  final Widget primaryContent;
  final Widget sideContent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final railWidth = (constraints.maxWidth * .28)
            .clamp(360.0, 560.0)
            .toDouble();
        return ColoredBox(
          color: GlobalColors.homeBackground,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: railWidth,
                child: ColoredBox(
                  color: GlobalColors.homeHeaderBackground,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(56, 54, 56, 40),
                      child: primaryContent,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: sideContent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
