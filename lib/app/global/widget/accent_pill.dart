import 'package:flutter/material.dart';

import '../accent.dart';
import '../styles/app_text_style.dart';

/// Small rounded label in the page accent ("Processing", "By PO", "12 left").
/// Text uses [AppAccent.text] so it stays readable on white.
Widget accentPill(double size, String text, {required AppAccent accent, IconData? icon, bool outlined = false}) {
  return _pill(
    size,
    text,
    fg: accent.text,
    fill: outlined ? Colors.white : accent.tint(0.12),
    border: outlined ? accent.tint(0.3) : null,
    icon: icon,
  );
}

/// Pill for API-provided status colors (e.g. delivery status); light colors
/// fall back to navy text via [readableOnWhite].
Widget statusPill(double size, String text, Color color, {IconData? icon}) {
  return _pill(size, text, fg: readableOnWhite(color), fill: color.withValues(alpha: 0.13), icon: icon);
}

Widget _pill(double size, String text, {required Color fg, required Color fill, Color? border, IconData? icon}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: size * 0.9, vertical: size * 0.35),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(size * 2),
      border: border != null ? Border.all(color: border) : null,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: size * 1.2, color: fg), SizedBox(width: size * 0.35)],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.custom(size, scale: 1.0, weight: FontWeight.w700, color: fg),
          ),
        ),
      ],
    ),
  );
}
