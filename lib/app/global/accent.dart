import 'package:flutter/material.dart';

import 'variables.dart';
import 'variables.dart' as palette show amber;

/// Single color source for every non-Home screen. The AppBar tile icon color is
/// the page's accent; cards, pills and progress bars read from the same value.
enum AppAccent {
  navy(navyDark, navyMid, navyDark),
  slate(navyMid, navyLight, navyMid), // Inventory: products, master data, transactions
  sky(skyBlue, skyBlueLight, skyBlueDark), // Receive · By PO
  sage(sageTeal, sageTealLight, sageTealDark), // Receive · By Supplier
  purple(mutedPurple, softPurple, mutedPurple), // Outflow · By Request / history
  amber(palette.amber, amberLight, amberDark), // Outflow · By Customer
  steel(steelBlue, lightSteelBlue, steelBlue); // Delivery

  const AppAccent(this.base, this.light, this.text);

  final Color base; // icons, progress, borders
  final Color light; // gradient end
  final Color text; // small text on white / tint

  Color tint([double a = 0.12]) => base.withValues(alpha: a);

  LinearGradient get gradient => LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [base, light]);
}

/// Header navy, used by the AppBar, main buttons and the bottom bar.
const LinearGradient navyGradient = LinearGradient(colors: [navyDark, navyMid]);

/// Picks a palette accent for a master-data item from its name (deterministic).
AppAccent accentFor(String name) => const [
      AppAccent.slate,
      AppAccent.sky,
      AppAccent.sage,
      AppAccent.purple,
      AppAccent.amber,
      AppAccent.steel,
    ][name.codeUnits.fold<int>(0, (a, c) => a + c) % 6];

/// API colors (e.g. `delivery_statuses.color`, default `#fff`) can be unreadable
/// on white — fall back to navy for light ones.
Color readableOnWhite(Color c) => c.computeLuminance() > 0.7 ? navyMid : c;
