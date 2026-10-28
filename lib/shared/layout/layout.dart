import 'package:flutter/material.dart';
import 'desktop_layout.dart';
import 'mobile_layout.dart';
import 'tablet_layout.dart';

enum AppLayoutType {
  mobile,
  tablet,
  desktop;

  /// The display size is stable while Android resizes the app viewport for
  /// the on-screen keyboard. `MediaQuery.size` is not: its height changes
  /// while typing, which must not cause a tablet page to be rebuilt as mobile.
  static Size displaySizeOf(BuildContext context) {
    final view = View.of(context);
    return view.physicalSize / view.devicePixelRatio;
  }

  static AppLayoutType fromContext(BuildContext context) {
    final screenSize = displaySizeOf(context);
    return resolve(
      maxWidth: screenSize.width,
      screenSize: screenSize,
      platform: Theme.of(context).platform,
    );
  }

  static AppLayoutType resolve({
    required double maxWidth,
    required Size screenSize,
    required TargetPlatform platform,
  }) {
    final isMobilePlatform =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;

    if (screenSize.shortestSide < 700) {
      return AppLayoutType.mobile;
    }

    if (isMobilePlatform) {
      return AppLayoutType.tablet;
    }

    if (maxWidth >= 1200) {
      return AppLayoutType.desktop;
    }

    return maxWidth >= 700 ? AppLayoutType.tablet : AppLayoutType.mobile;
  }

  bool get isMobile => this == AppLayoutType.mobile;
  bool get isTablet => this == AppLayoutType.tablet;
  bool get isDesktop => this == AppLayoutType.desktop;
}

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
        final screenSize = AppLayoutType.displaySizeOf(context);
        final layoutType = AppLayoutType.resolve(
          maxWidth: constraints.maxWidth,
          screenSize: screenSize,
          platform: Theme.of(context).platform,
        );

        // A page can be hosted by a box layout in one mode and by a sliver
        // layout in another. Give each mode its own subtree so Flutter never
        // tries to reparent inherited-widget dependents while resizing or
        // rotating the device.
        return KeyedSubtree(
          key: ValueKey(layoutType),
          child: switch (layoutType) {
            AppLayoutType.mobile => MobileLayout(
              primaryContent: primaryContent,
              sideContent: sideContent,
            ),
            AppLayoutType.tablet => TabletLayout(
              primaryContent: primaryContent,
              sideContent: sideContent,
            ),
            AppLayoutType.desktop => DesktopLayout(
              primaryContent: primaryContent,
              sideContent: sideContent,
            ),
          },
        );
      },
    );
  }
}
