import 'package:flutter/material.dart';
import '../utils/global_colors.dart';

class TabletLayout extends StatelessWidget {
  const TabletLayout({
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
          final railWidth = (constraints.maxWidth * 0.273)
              .clamp(260.0, 320.0)
              .toDouble();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: railWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: GlobalColors.homeHeaderBackground,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: primaryContent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: GlobalColors.homeBackground,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                        child: sideContent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ColoredBox(
          color: GlobalColors.homeBackground,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: GlobalColors.homeHeaderBackground,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 24, 32, 28),
                      child: primaryContent,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(32, 22, 32, 32),
                sliver: SliverToBoxAdapter(child: sideContent),
              ),
            ],
          ),
        );
      },
    );
  }
}
