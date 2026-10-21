import 'package:flutter/material.dart';

/// Shared colour tokens for the application.
///
/// Change a value here to update every semantic colour that refers to it.
class AppPalette {
  AppPalette._();

  static const white = Colors.white;
  static const black = Colors.black;

  static const ink = Color(0xFF111827);
  static const slate = Color(0xFF6B7280);
  static const tealDark = Color(0xFF153C3F);
  static const teal = Color(0xFF21666B);
  static const tealMuted = Color(0xFFAFC4C4);

  static const canvas = Color(0xFFF5F2ED);
  static const surfaceCool = Color(0xFFEFF4F4);
  static const borderCool = Color(0xFFE3E8EF);
  static const borderWarm = Color(0xFFE1D9CD);
  static const dividerWarm = Color(0xFFE5E0D7);
  static const outlineWarm = Color(0xFFD4CCC0);

  static const buttonMuted = Color(0xFF80949E);
  static const orange = Color(0xFFAE5A25);
  static const amberLight = Color(0xFFFFEDC7);
  static const amberDark = Color(0xFF7A4300);

  static const slateDark = Color(0xFF59676B);
  static const charcoal = Color(0xFF243236);
  static const slateLight = Color(0xFF9BA8AA);
}

class GlobalColors {
  GlobalColors._();

  // Semantic aliases used by existing UI components.
  static const primaryText = AppPalette.ink;
  static const secondaryText = AppPalette.slate;
  static const divider = AppPalette.borderCool;
  static const buttonBackground = AppPalette.buttonMuted;
  static const billingButtonBackground = AppPalette.orange;
  static const homeBackground = AppPalette.canvas;
  static const homeHeaderBackground = AppPalette.tealDark;
  static const homeHeaderForeground = AppPalette.white;
  static const homeActionBackground = AppPalette.teal;
  static const homeHeaderLabel = AppPalette.tealMuted;
  static const homeStatusBackground = AppPalette.amberLight;
  static const homeStatusForeground = AppPalette.amberDark;
  static const billingCardBorder = AppPalette.borderWarm;
  static const billingHeaderBackground = AppPalette.surfaceCool;
  static const billingHeaderText = AppPalette.slateDark;
  static const billingRowDivider = AppPalette.dividerWarm;
  static const billingOutline = AppPalette.outlineWarm;
  static const billingIcon = AppPalette.charcoal;
  static const billingChevron = AppPalette.slateLight;

  static Color buttonForeground(Color background) {
    return background.computeLuminance() > 0.5
        ? AppPalette.black
        : AppPalette.white;
  }

  static const buttonTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const clientTitleTextStyle = TextStyle(
    color: primaryText,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const clientIdTextStyle = TextStyle(
    color: secondaryText,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const infoLabelTextStyle = TextStyle(
    color: secondaryText,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const infoValueTextStyle = TextStyle(
    color: primaryText,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static const buttonMinimumSize = Size.fromHeight(56);
  static const buttonPadding = EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 12,
  );
  static const buttonIconSize = 24.0;
}
