import 'package:flutter/material.dart';

import '../variables.dart';

/// Outlined ▼/▲ leading for stock transaction rows (IN = green south arrow,
/// OUT = red north arrow).
Widget stockDirectionIcon(double size, {required bool isIn}) {
  final color = isIn ? stockInColor : stockOutColor;
  return Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
    ),
    child: Icon(isIn ? Icons.south_rounded : Icons.north_rounded, color: color, size: 18),
  );
}
