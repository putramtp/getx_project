import 'package:flutter/material.dart';

import '../styles/app_text_style.dart';

/// Shared building blocks for the fill / scan action screens (receive fill,
/// outflow scan) and the serial-confirm screen — so the item header, the
/// quantity-stats card, the scan FAB and the Clear/Continue bottom bar look
/// identical everywhere. Each screen supplies its own accent color + actions.

/// One labelled number in the stats card (Expected / Received / Filled…).
class FillStat {
  final String label;
  final String value;
  final Color color;
  const FillStat(this.label, this.value, this.color);
}

/// Item-name header card shown at the top of a fill/scan screen.
Widget orderFillHeaderCard({
  required double size,
  required String name,
  required Color accent,
}) {
  return Container(
    padding: EdgeInsets.all(size * 1.6),
    decoration: BoxDecoration(
      color: accent.withOpacity(0.08),
      borderRadius: BorderRadius.circular(size * 2),
      border: Border.all(color: accent.withOpacity(0.18)),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(size * 1.1),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(size * 1.2),
          ),
          child: Icon(Icons.inventory_2_rounded, color: accent, size: size * 2.6),
        ),
        SizedBox(width: size * 1.4),
        Expanded(
          child: Text(name,
              style: AppTextStyle.h5(size),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}

/// Horizontal stats card (Expected / Received / Filled / Remaining …).
Widget orderFillStatsCard({required double size, required List<FillStat> stats}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: size * 1.6, vertical: size * 1.4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(size * 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final s in stats)
          Column(
            children: [
              Text(s.value,
                  style: AppTextStyle.custom(size,
                      scale: 1.9,
                      weight: FontWeight.bold,
                      color: s.color)),
              SizedBox(height: size * 0.3),
              Text(s.label,
                  style: AppTextStyle.small(size, color: Colors.grey.shade600)
                      .copyWith(fontSize: size * 1.2)),
            ],
          ),
      ],
    ),
  );
}

/// The big circular scan/fill action button (centre-docked FAB).
Widget orderScanFab({
  required double size,
  required Color color,
  required IconData icon,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: size * 6.5,
    height: size * 6.5,
    child: FloatingActionButton(
      backgroundColor: color,
      foregroundColor: Colors.white,
      elevation: 5,
      shape: const CircleBorder(),
      onPressed: onPressed,
      child: Icon(icon, size: size * 3.4),
    ),
  );
}

/// Bottom Clear / Continue bar shared by fill & scan screens.
Widget orderFillBottomBar({
  required double size,
  required bool clearEnabled,
  required VoidCallback? onClear,
  required bool continueEnabled,
  required VoidCallback? onContinue,
  required Color accent,
}) {
  return Container(
    height: size * 5.5,
    margin: EdgeInsets.only(left: size * 2.4, right: size * 2.4, bottom: size * 1.6),
    padding: EdgeInsets.symmetric(horizontal: size * 1.2),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(size * 4),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: clearEnabled ? onClear : null,
          icon: Icon(Icons.delete_forever_rounded,
              color: clearEnabled ? Colors.red : Colors.grey, size: size * 2.4),
          label: Text("Clear",
              style: AppTextStyle.custom(size,
                  scale: 1.5,
                  color: clearEnabled ? Colors.red : Colors.grey,
                  weight: FontWeight.bold)),
        ),
        TextButton.icon(
          onPressed: continueEnabled ? onContinue : null,
          icon: Icon(Icons.arrow_forward_rounded,
              color: continueEnabled ? accent : Colors.grey, size: size * 2.4),
          label: Text("Continue",
              style: AppTextStyle.custom(size,
                  scale: 1.5,
                  color: continueEnabled ? accent : Colors.grey,
                  weight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

/// Empty placeholder for the results list.
Widget orderFillEmptyState({
  required double size,
  required IconData icon,
  required String message,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: size * 7, color: Colors.grey.shade300),
        SizedBox(height: size * 1.4),
        Text(message, style: AppTextStyle.body(size, color: Colors.grey.shade500)),
      ],
    ),
  );
}

/// White rounded container that wraps the results list.
Widget orderFillResultsContainer({required double size, required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(size * 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}
