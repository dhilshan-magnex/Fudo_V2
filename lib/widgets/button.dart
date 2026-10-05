import 'package:flutter/material.dart';
import '../utils/global_colors.dart';

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
          return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: compact ? 18 : 28),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              outlined ? GlobalColors.billingIcon : GlobalColors.homeHeaderForeground,
          backgroundColor:
              outlined ? Colors.white : GlobalColors.homeActionBackground,
          side: BorderSide(
            color: outlined ? GlobalColors.billingOutline : Colors.transparent,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
          padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 16),
          textStyle: TextStyle(
            fontSize: compact ? 14 : 25,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
        },
      );
}

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
        final screenSize = MediaQuery.sizeOf(context);
        final isDesktop = screenSize.width >= 1200;
        if (wrapButtons && isDesktop && buttons.length >= 8) {
          const gap = 24.0;
          final columnWidth = (constraints.maxWidth - gap * 2) / 3;
          final coreButtons = buttons.skip(1).take(4).toList();
          final compactButtons = buttons.skip(5).toList();

          Widget buildRow(List<HomeActionButton> rowButtons) => Row(
            children: [
              for (var index = 0; index < rowButtons.length; index++) ...[
                if (index > 0) const SizedBox(width: gap),
                Expanded(child: rowButtons[index]),
              ],
            ],
          );

          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    SizedBox(width: columnWidth * 2 + gap, child: buttons.first),
                    const SizedBox(width: gap),
                    Expanded(child: coreButtons.first),
                  ],
                ),
              ),
              const SizedBox(height: gap),
              Expanded(child: buildRow(coreButtons.skip(1).take(3).toList())),
              const SizedBox(height: gap),
              Expanded(child: buildRow(compactButtons)),
            ],
          );
        }

        final isTabletLandscape =
            screenSize.shortestSide >= 700 &&
            screenSize.width > screenSize.height &&
            constraints.maxWidth >= 480 &&
            constraints.maxWidth < 1000;

        if (wrapButtons && isTabletLandscape && buttons.length > 1) {
          const gap = 16.0;
          final panelHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : screenSize.height - 64;
          final rowHeight = ((panelHeight - gap * 2) / 3)
              .clamp(88.0, 260.0)
              .toDouble();
          final columnWidth = (constraints.maxWidth - gap * 2) / 3;
          final coreButtons = buttons.skip(1).take(4).toList();
          final compactButtons = buttons.skip(5).toList();

          Widget buildRow(List<HomeActionButton> rowButtons) {
            return SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  for (var index = 0; index < rowButtons.length; index++) ...[
                    if (index > 0) const SizedBox(width: gap),
                    Expanded(child: rowButtons[index]),
                  ],
                ],
              ),
            );
          }

          return Column(
            children: [
              SizedBox(
                height: rowHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: columnWidth * 2 + gap,
                      child: buttons.first,
                    ),
                    const SizedBox(width: gap),
                    Expanded(
                      child: coreButtons.isEmpty
                          ? const SizedBox.shrink()
                          : coreButtons.first,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: gap),
              buildRow(coreButtons.skip(1).take(3).toList()),
              const SizedBox(height: gap),
              buildRow(compactButtons),
            ],
          );
        }

        final isTabletPortrait =
            screenSize.shortestSide >= 700 && screenSize.height > screenSize.width;
        if (wrapButtons && isTabletPortrait && buttons.isNotEmpty) {
          const gap = 16.0;
          final featuredHeight = (constraints.maxWidth * 0.30)
              .clamp(180.0, 250.0)
              .toDouble();
          final tileHeight = (constraints.maxWidth * 0.29)
              .clamp(170.0, 230.0)
              .toDouble();
          final compactHeight = (constraints.maxWidth * 0.20)
              .clamp(108.0, 150.0)
              .toDouble();
          final tileWidth = (constraints.maxWidth - gap) / 2;
          final compactWidth = (constraints.maxWidth - gap * 2) / 3;
          final tileButtons = buttons.skip(1).take(4).toList();
          final compactButtons = buttons.skip(5).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: featuredHeight, child: buttons.first),
              const SizedBox(height: gap),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: tileButtons
                    .map((button) => SizedBox(
                          width: tileWidth,
                          height: tileHeight,
                          child: button,
                        ))
                    .toList(),
              ),
              const SizedBox(height: gap),
              Wrap(
                spacing: gap,
                children: compactButtons
                    .map((button) => SizedBox(
                          width: compactWidth,
                          height: compactHeight,
                          child: button,
                        ))
                    .toList(),
              ),
            ],
          );
        }

        if (wrapButtons && isMobile && buttons.isNotEmpty) {
          final panelHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 560.0;
          final gap = (panelHeight * 0.018).clamp(6.0, 13.0).toDouble();
          final featuredHeight = (panelHeight * 0.22).clamp(64.0, 152.0);
          final tileHeight = (panelHeight * 0.20).clamp(52.0, 132.0);
          final compactHeight = (panelHeight * 0.19).clamp(50.0, 120.0);
          final itemWidth = (constraints.maxWidth - gap) / 2;
          final compactWidth = (constraints.maxWidth - gap * 2) / 3;
          final gridButtons = buttons.skip(1).take(4).toList();
          final compactButtons = buttons.skip(5).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: featuredHeight, child: buttons.first),
              SizedBox(height: gap),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: gridButtons
                    .map(
                      (button) => SizedBox(
                        width: itemWidth,
                        height: tileHeight,
                        child: button,
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: gap),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: compactButtons
                    .map(
                      (button) => SizedBox(
                        width: compactWidth,
                        height: compactHeight,
                        child: button,
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        }

        final isTabletPanel =
            constraints.maxWidth >= 700 && constraints.maxWidth < 900;
        if (wrapButtons && isTabletPanel && buttons.isNotEmpty) {
          const gap = 16.0;
          final itemWidth = (constraints.maxWidth - gap) / 2;
          final otherButtons = buttons.skip(1).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 96, child: buttons.first),
              const SizedBox(height: gap),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: otherButtons
                    .map(
                      (button) =>
                          SizedBox(width: itemWidth, height: 84, child: button),
                    )
                    .toList(),
              ),
            ],
          );
        }

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

enum HomeActionButtonMode { featured, tile, compact }

class HomeActionButton extends StatelessWidget {
  const HomeActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.mode = HomeActionButtonMode.tile,
    this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;
  final HomeActionButtonMode mode;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isMobile = screenSize.shortestSide < 700;
    final isTabletLandscape =
        screenSize.shortestSide >= 700 &&
        screenSize.width < 1200 &&
        screenSize.width > screenSize.height;
    final isTablet = screenSize.shortestSide >= 700;
    final buttonBackground = backgroundColor ??
        (isTablet || !isMobile
            ? mode == HomeActionButtonMode.compact
                ? Colors.white
                : GlobalColors.homeActionBackground
            : GlobalColors.buttonBackground);
    final buttonForeground = GlobalColors.buttonForeground(buttonBackground);

    if (isTabletLandscape) {
      final buttonRadius = mode == HomeActionButtonMode.featured ? 22.0 : 20.0;
      final buttonChild = switch (mode) {
        HomeActionButtonMode.featured => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 48),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
        HomeActionButtonMode.tile => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        HomeActionButtonMode.compact => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      };

      return TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: buttonForeground,
          backgroundColor: buttonBackground,
          padding: EdgeInsets.all(
            mode == HomeActionButtonMode.featured ? 32 : 24,
          ),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
            side: BorderSide(
              color: mode == HomeActionButtonMode.compact
                  ? GlobalColors.divider
                  : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: buttonChild,
      );
    }

    if (!isMobile) {
      if (isTablet || screenSize.width >= 1200) {
        final buttonRadius = mode == HomeActionButtonMode.featured ? 22.0 : 20.0;
        final buttonChild = switch (mode) {
          HomeActionButtonMode.featured => Row(
            children: [
              Icon(icon, size: 52),
              const SizedBox(width: 30),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 20),
                      ),
                  ],
                ),
              ),
            ],
          ),
          HomeActionButtonMode.tile => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 36),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          HomeActionButtonMode.compact => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        };

        return TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: buttonForeground,
            backgroundColor: buttonBackground,
            padding: EdgeInsets.all(
              mode == HomeActionButtonMode.featured ? 32 : 24,
            ),
            alignment: Alignment.centerLeft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius),
              side: BorderSide(
                color: mode == HomeActionButtonMode.compact
                    ? GlobalColors.divider
                    : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: buttonChild,
        );
      }

      if (mode == HomeActionButtonMode.featured) {
        return TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: buttonForeground,
            backgroundColor: buttonBackground,
            minimumSize: const Size.fromHeight(88),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            alignment: Alignment.centerLeft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: GlobalColors.divider, width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 36),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: GlobalColors.buttonIconSize),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: buttonForeground,
          backgroundColor: buttonBackground,
          minimumSize: GlobalColors.buttonMinimumSize,
          padding: GlobalColors.buttonPadding,
          alignment: Alignment.centerLeft,
          textStyle: GlobalColors.buttonTextStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: GlobalColors.divider, width: 1),
          ),
        ),
      );
    }

    final isShortScreen = MediaQuery.sizeOf(context).height < 720;
    final buttonRadius = mode == HomeActionButtonMode.featured ? 22.0 : 18.0;
    final child = switch (mode) {
      HomeActionButtonMode.featured => Row(
        children: [
          Icon(icon, size: isShortScreen ? 28 : 36),
          SizedBox(width: isShortScreen ? 10 : 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: isShortScreen ? 18 : 24),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isShortScreen ? 11 : 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      HomeActionButtonMode.tile => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxHeight < 56) {
            return Row(
              children: [
                Icon(icon, size: isShortScreen ? 20 : 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: isShortScreen ? 14 : 17),
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: isShortScreen ? 22 : 28),
              const Spacer(),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: isShortScreen ? 14 : 17),
              ),
            ],
          );
        },
      ),
      HomeActionButtonMode.compact => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxHeight < 56) {
            return Row(
              children: [
                Icon(icon, size: isShortScreen ? 18 : 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: isShortScreen ? 11 : 14),
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: isShortScreen ? 18 : 26),
              const Spacer(),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: isShortScreen ? 11 : 14),
              ),
            ],
          );
        },
      ),
    };

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: buttonForeground,
        backgroundColor: buttonBackground,
        minimumSize: const Size.fromHeight(56),
        padding: EdgeInsets.all(isShortScreen ? 7 : 12),
        alignment: Alignment.centerLeft,
        textStyle: GlobalColors.buttonTextStyle.copyWith(
          fontSize: isShortScreen ? 15 : 18,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          side: const BorderSide(color: GlobalColors.divider, width: 1),
        ),
      ),
      child: child,
    );
  }
}
