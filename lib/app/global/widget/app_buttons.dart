import 'package:flutter/material.dart';

import '../accent.dart';
import '../styles/app_text_style.dart';
import '../variables.dart';

/// Full-width main action on header navy. `onPressed == null` renders grey;
/// [loading] shows a spinner and ignores taps.
Widget navyButton(
  double size,
  String label, {
  required VoidCallback? onPressed,
  IconData? icon,
  bool loading = false,
}) {
  final enabled = onPressed != null && !loading;
  final radius = BorderRadius.circular(size * 1.4);
  return Container(
    width: double.infinity,
    height: size * 4.6,
    decoration: BoxDecoration(
      gradient: onPressed != null ? navyGradient : null,
      color: onPressed != null ? null : Colors.grey.shade400,
      borderRadius: radius,
      boxShadow: onPressed != null
          ? [BoxShadow(color: navyDark.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]
          : null,
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: enabled ? onPressed : null,
        child: Center(
          child: loading
              ? SizedBox(
                  width: size * 2,
                  height: size * 2,
                  child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: size * 1.8),
                      SizedBox(width: size * 0.8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.custom(size, scale: 1.15, weight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}

/// White button with a [color] outline — delivery "Mark `<Status>`" (API color)
/// and "Edit details" (navy). Light API colors fall back to navy.
Widget accentOutlineButton(
  double size,
  String label, {
  required Color color,
  required VoidCallback? onPressed,
  IconData? icon,
}) {
  final fg = readableOnWhite(color);
  return OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: fg,
      side: BorderSide(color: fg.withValues(alpha: 0.45), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(size * 1.2)),
      padding: EdgeInsets.symmetric(horizontal: size * 1.4, vertical: size * 1.0),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: size * 1.6, color: fg), SizedBox(width: size * 0.6)],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.custom(size, scale: 1.15, weight: FontWeight.w700, color: fg),
          ),
        ),
      ],
    ),
  );
}
