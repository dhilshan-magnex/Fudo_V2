import 'package:flutter/material.dart';
import '../utils/global_colors.dart';

class MobileLayout extends StatelessWidget {
  const MobileLayout({
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
        final isLandscape = constraints.maxWidth > constraints.maxHeight;

        if (isLandscape) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: GlobalColors.homeHeaderBackground,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: primaryContent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: sideContent),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: GlobalColors.homeHeaderBackground,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: primaryContent,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: sideContent,
              ),
            ),
          ],
        );
      },
    );
  }
}
