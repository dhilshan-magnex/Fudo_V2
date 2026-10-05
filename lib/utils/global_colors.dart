import 'package:flutter/material.dart';

class GlobalColors {
  static const primaryText = Color(0xFF111827);
  static const secondaryText = Color(0xFF6B7280);
  static const divider = Color(0xFFE3E8EF);
  static const buttonBackground = Color(0xFF80949E);
  static const billingButtonBackground = Color.fromARGB(255, 174, 90, 37);
  static const homeBackground = Color(0xFFF5F2ED);
  static const homeHeaderBackground = Color(0xFF153C3F);
  static const homeHeaderForeground = Colors.white;
  static const homeActionBackground = Color(0xFF21666B);
  static const homeHeaderLabel = Color(0xFFAFC4C4);
  static const homeStatusBackground = Color(0xFFFFEDC7);
  static const homeStatusForeground = Color(0xFF7A4300);
  static const billingCardBorder = Color(0xFFE1D9CD);
  static const billingHeaderBackground = Color(0xFFEFF4F4);
  static const billingHeaderText = Color(0xFF59676B);
  static const billingRowDivider = Color(0xFFE5E0D7);
  static const billingOutline = Color(0xFFD4CCC0);
  static const billingIcon = Color(0xFF243236);
  static const billingChevron = Color(0xFF9BA8AA);

  static Color buttonForeground(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
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
