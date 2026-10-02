import 'package:flutter/material.dart';
import 'desktop_layout.dart';
import 'mobile_layout.dart';
import 'tablet_layout.dart';

class HomeLayout extends StatelessWidget {
  const HomeLayout({
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
        final maxWidth = constraints.maxWidth;
        final screenSize = MediaQuery.sizeOf(context);
        final isCompactDevice = screenSize.shortestSide < 700;
        final platform = Theme.of(context).platform;
        final isLargeMobilePlatform =
            platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS;

        if (isCompactDevice) {
          return MobileLayout(
            primaryContent: primaryContent,
            sideContent: sideContent,
          );
        }

        if (isLargeMobilePlatform && screenSize.shortestSide >= 700) {
          return TabletLayout(
            primaryContent: primaryContent,
            sideContent: sideContent,
          );
        }

        if (maxWidth >= 1200) {
          return DesktopLayout(
            primaryContent: primaryContent,
            sideContent: sideContent,
          );
        }

        if (maxWidth >= 700) {
          return TabletLayout(
            primaryContent: primaryContent,
            sideContent: sideContent,
          );
        }

        return MobileLayout(
          primaryContent: primaryContent,
          sideContent: sideContent,
        );
      },
    );
  }
}
