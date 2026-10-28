import 'package:flutter/material.dart';

import '../styles/app_text_style.dart';
import '../variables.dart';

/// Stock status of a product by its remaining qty. `low` uses the same cut-off
/// as `ProductSummaryModel.lowStock` and the backend's LOW_STOCK_THRESHOLD.
enum StockLevel {
  ok('in stock', stockInColor),
  low('low', amberDark),
  out('out', stockOutColor);

  const StockLevel(this.label, this.color);
  final String label;
  final Color color;

  static const lowThreshold = 10;

  static StockLevel of(int remaining) => remaining <= 0
      ? StockLevel.out
      : remaining < lowThreshold
          ? StockLevel.low
          : StockLevel.ok;
}

/// Square leading for product rows: the remaining qty over its status label,
/// tinted and outlined in the [StockLevel] color.
Widget stockLevelTile(double size, int remaining) {
  final level = StockLevel.of(remaining);
  return Container(
    key: const Key('productStockLevel'),
    width: size * 5.4,
    height: size * 5.4,
    padding: EdgeInsets.symmetric(horizontal: size * 0.4),
    decoration: BoxDecoration(
      color: level.color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(size * 1.4),
      border: Border.all(color: level.color.withValues(alpha: 0.5), width: 1.5),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('$remaining', maxLines: 1, style: AppTextStyle.h4(size, color: level.color, weight: FontWeight.w800)),
        ),
        Text(
          level.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.custom(size, scale: 0.95, color: level.color, weight: FontWeight.w700),
        ),
      ],
    ),
  );
}
