import 'package:flutter/material.dart';

import '../accent.dart';
import '../styles/app_text_style.dart';
import '../variables.dart';
import 'accent_header_card.dart';
import 'accent_pill.dart';

/// Shared building blocks for the fill / scan action screens (receive fill,
/// outflow scan) — so the item header, the scan FAB, the results title and the
/// Clear/Continue bottom bar look identical everywhere. Each screen supplies
/// its own accent + actions.

/// Item card at the top of a fill/scan screen: item name, "N left" badge,
/// target / received / [doneLabel] / remaining stats and a two-tone progress.
Widget orderFillItemHeader(
  double size, {
  required AppAccent accent,
  required String name,
  required String targetLabel,
  required int target,
  required int received,
  required String doneLabel,
  required int done,
}) {
  final remaining = target - (received + done);
  return accentHeaderCard(
    size: size,
    accent: accent,
    icon: Icons.inventory_2_rounded,
    label: 'Item',
    title: name,
    badge: accentPill(
      size,
      remaining > 0 ? '$remaining left' : 'Done',
      accent: accent,
      outlined: true,
    ),
    stats: [
      HeaderStat(targetLabel, '$target', color: Colors.grey.shade700),
      HeaderStat('Received', '$received', color: navyMid),
      HeaderStat(doneLabel, '$done', color: accent.base),
      HeaderStat(
        'Remaining',
        '$remaining',
        color: remaining <= 0 ? Colors.grey : stockOutColor,
      ),
    ],
    progress: AccentProgress(
      [
        ProgressSegment(target > 0 ? received / target : 0, navyMid),
        ProgressSegment(target > 0 ? done / target : 0, accent.base),
      ],
      caption:
          '$received received · $done ${doneLabel.toLowerCase()} of $target',
    ),
  );
}

/// The big circular scan/fill action button (centre-docked FAB): white with a
/// navy ring, the icon in the page accent [color].
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
      key: const Key('orderFillFab'),
      backgroundColor: Colors.white,
      foregroundColor: color,
      elevation: 5,
      shape: const CircleBorder(side: BorderSide(color: navyDark, width: 3)),
      onPressed: onPressed,
      child: Icon(icon, size: size * 3.4, color: color),
    ),
  );
}

/// Bottom Clear / Continue bar shared by fill & scan screens, on header navy.
/// [accent] is kept for callers; the bar itself is always navy.
Widget orderFillBottomBar({
  required double size,
  required bool clearEnabled,
  required VoidCallback? onClear,
  required bool continueEnabled,
  required VoidCallback? onContinue,
  required Color accent,
}) {
  final disabled = Colors.white.withValues(alpha: 0.4);
  Widget action(
    String label,
    IconData icon,
    bool enabled,
    VoidCallback? onTap,
    Color iconColor,
    Color textColor,
  ) {
    return TextButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, color: enabled ? iconColor : disabled, size: size * 2.4),
      label: Text(
        label,
        style: AppTextStyle.custom(
          size,
          scale: 1.5,
          color: enabled ? textColor : disabled,
          weight: FontWeight.bold,
        ),
      ),
    );
  }

  // SafeArea: lift the bar above Android's 3-button navigation bar (edge-to-edge).
  return SafeArea(
    top: false,
    child: Container(
      height: size * 5.5,
      margin: EdgeInsets.only(
        left: size * 2.4,
        right: size * 2.4,
        bottom: size * 1.6,
      ),
      padding: EdgeInsets.symmetric(horizontal: size * 1.2),
      decoration: BoxDecoration(
        gradient: navyGradient,
        borderRadius: BorderRadius.circular(size * 4),
        boxShadow: [
          BoxShadow(
            color: navyDark.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          action(
            "Clear",
            Icons.delete_forever_rounded,
            clearEnabled,
            onClear,
            clearOnNavy,
            Colors.white.withValues(alpha: 0.78),
          ),
          action(
            "Continue",
            Icons.arrow_forward_rounded,
            continueEnabled,
            onContinue,
            Colors.white,
            Colors.white,
          ),
        ],
      ),
    ),
  );
}

/// "Filled Results" / "Scanned Results" heading with an "N entries" pill.
Widget orderFillResultsTitle(
  double size,
  String title, {
  required int count,
  required AppAccent accent,
}) {
  return Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: AppTextStyle.h5(size, weight: FontWeight.w700),
        ),
      ),
      accentPill(
        size,
        count == 1 ? '1 entry' : '$count entries',
        accent: accent,
      ),
    ],
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
        Text(
          message,
          style: AppTextStyle.body(size, color: Colors.grey.shade500),
        ),
      ],
    ),
  );
}

/// White rounded container that wraps the results list.
Widget orderFillResultsContainer({
  required double size,
  required Widget child,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(size * 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    // ListTile rows paint their ink on the nearest Material; without this one
    // the white box above would hide them (and Flutter asserts in debug).
    child: Material(type: MaterialType.transparency, child: child),
  );
}
