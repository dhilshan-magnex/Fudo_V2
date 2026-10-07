import 'package:flutter/material.dart';

import '../../utils/global_colors.dart';

enum AppButtonVariant { filled, outlined, compact, text }

/// Shared button shell for standard labelled actions.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.filled,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.padding,
    this.borderRadius = 12,
    this.iconSize,
    this.fontSize,
    this.alignment = Alignment.center,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double? iconSize;
  final double? fontSize;
  final AlignmentGeometry alignment;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final isOutlined = variant == AppButtonVariant.outlined;
    final isText = variant == AppButtonVariant.text;
    final resolvedBackground = backgroundColor ??
        (isOutlined || isText ? Colors.transparent : GlobalColors.homeActionBackground);
    final resolvedForeground = foregroundColor ??
        (isOutlined || isText
            ? GlobalColors.billingIcon
            : GlobalColors.buttonForeground(resolvedBackground));
    final resolvedBorder = borderColor ??
        (isOutlined ? GlobalColors.billingOutline : Colors.transparent);
    final content = icon == null
        ? Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: iconSize ?? (variant == AppButtonVariant.compact ? 20 : 24),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          );

    return SizedBox(
      width: expand ? double.infinity : null,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: resolvedBackground,
          foregroundColor: resolvedForeground,
          alignment: alignment,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(color: resolvedBorder),
          ),
          textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
        ),
        child: content,
      ),
    );
  }
}
