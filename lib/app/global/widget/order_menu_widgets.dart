import 'package:flutter/material.dart';

import '../accent.dart';
import '../styles/app_text_style.dart';
import '../variables.dart';

/// Shared building blocks for the Receive / Outflow order menus.
///
/// Both menus share an identical structure (a tappable gradient "hero"
/// linking to the full list, a section header, and a pair of large option
/// cards), so the visuals live here once and each menu just supplies its
/// own copy, colors and routes.

/// Translucent decor circle (dashboard greeting-card motif).
Widget decorCircle(double diameter, Color color) => Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );

/// Large tappable gradient banner at the top of an order menu.
/// Mirrors the dashboard greeting card (gradient + translucent circles).
Widget orderMenuHero({
  required double size,
  required String title,
  required String subtitle,
  required IconData icon,
  required List<Color> gradientColors,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(size * 2.4),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 2.4),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -size * 4,
                right: -size * 4,
                child: decorCircle(size * 16, Colors.white.withValues(alpha: 0.08)),
              ),
              Positioned(
                bottom: -size * 5,
                left: -size * 4,
                child: decorCircle(size * 14, Colors.white.withValues(alpha: 0.06)),
              ),
              Padding(
                padding: EdgeInsets.all(size * 2.2),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(size * 1.6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: size * 3.6, color: Colors.white),
                    ),
                    SizedBox(width: size * 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyle.h2(size, color: Colors.white)
                                .copyWith(letterSpacing: 0.3),
                          ),
                          SizedBox(height: size * 0.6),
                          Text(subtitle,
                              style:
                                  AppTextStyle.body(size, color: Colors.white70)),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(size * 0.9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: size * 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Section header: colored accent bar + tinted icon chip + title.
/// Matches the dashboard `_sectionTitle` pattern.
Widget orderMenuSectionHeader(
    double size, String title, IconData icon, Color color) {
  return Row(
    children: [
      Container(
        width: size * 0.5,
        height: size * 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size),
        ),
      ),
      SizedBox(width: size * 1.2),
      Container(
        padding: EdgeInsets.all(size * 0.8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(size),
        ),
        child: Icon(icon, size: size * 2, color: color),
      ),
      SizedBox(width: size * 1.2),
      Text(title, style: AppTextStyle.h5(size)),
    ],
  );
}

/// One large option card (e.g. "By Purchase-order"). Designed to live in a
/// Row + Expanded pair wrapped in IntrinsicHeight so both cards share height.
Widget orderMenuTile({
  required double size,
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(size * 2),
      onTap: onTap,
      splashColor: color.withValues(alpha: 0.15),
      highlightColor: color.withValues(alpha: 0.08),
      child: Container(
        padding: EdgeInsets.all(size * 1.8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(size * 1.4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, Color.lerp(color, Colors.white, 0.35)!],
                ),
                borderRadius: BorderRadius.circular(size * 1.4),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: size * 3.2),
            ),
            SizedBox(height: size * 1.6),
            Text(title,
                style: AppTextStyle.bodyBold(size),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            SizedBox(height: size * 0.4),
            Text(subtitle,
                style: AppTextStyle.small(size, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const Spacer(),
            SizedBox(height: size * 1.4),
            Row(
              children: [
                Text("Open",
                    style: AppTextStyle.small(size, color: color)
                        .copyWith(fontWeight: FontWeight.bold)),
                SizedBox(width: size * 0.4),
                Icon(Icons.arrow_forward_rounded, size: size * 1.6, color: color),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// White tile-style card linking to another module (e.g. "Deliveries" on the
/// Outflow menu): gradient icon tile in [accent], title/subtitle and "Open →".
Widget orderMenuInfoCard({
  required double size,
  required String title,
  required String subtitle,
  required IconData icon,
  required AppAccent accent,
  required VoidCallback onTap,
}) {
  final radius = BorderRadius.circular(size * 2);
  return Material(
    color: Colors.white,
    borderRadius: radius,
    child: InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Ink(
        padding: EdgeInsets.all(size * 1.6),
        decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: accent.tint(0.18))),
        child: Row(
          children: [
            Container(
              width: size * 4.4,
              height: size * 4.4,
              decoration: BoxDecoration(gradient: accent.gradient, borderRadius: BorderRadius.circular(size * 1.3)),
              child: Icon(icon, color: Colors.white, size: size * 2.2),
            ),
            SizedBox(width: size * 1.4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.h5(size, weight: FontWeight.w700, color: navyDark)),
                  SizedBox(height: size * 0.2),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyle.small(size)),
                ],
              ),
            ),
            SizedBox(width: size * 0.8),
            Text("Open", style: AppTextStyle.bodyBold(size, color: accent.text)),
            Icon(Icons.arrow_forward_rounded, size: size * 1.6, color: accent.text),
          ],
        ),
      ),
    ),
  );
}

