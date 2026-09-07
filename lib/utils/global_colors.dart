import 'package:flutter/material.dart';

class GlobalColors {
	static const primaryText = Color(0xFF111827);
	static const secondaryText = Color(0xFF6B7280);
	static const divider = Color(0xFFE3E8EF);
	static const buttonBackground = Color(0xFF80949E);

	static Color buttonForeground(Color background) {
		return background.computeLuminance() > 0.5
			? Colors.black
			: Colors.white;
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
