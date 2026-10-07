import 'package:flutter/material.dart';
import '../utils/global_colors.dart';

/// A reusable single-line label for page headings and table labels.
class AppLabel extends StatelessWidget {
  const AppLabel(
    this.text, {
    super.key,
    required this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final String text;
  final TextStyle style;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) => Text(
        text,
        maxLines: maxLines,
        overflow: overflow,
        style: style,
      );
}

class ClientDetailLabel extends StatelessWidget {
  const ClientDetailLabel({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: GlobalColors.secondaryText),
        const SizedBox(width: 7),
        SizedBox(
          width: 80,
          child: Text(label, style: GlobalColors.infoLabelTextStyle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GlobalColors.infoValueTextStyle,
          ),
        ),
      ],
    );
  }
}
