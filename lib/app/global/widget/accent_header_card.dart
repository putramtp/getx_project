import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../accent.dart';
import '../styles/app_text_style.dart';
import '../variables.dart';
import 'order_menu_widgets.dart';

/// One labelled value in the [accentHeaderCard] stats box.
class HeaderStat {
  const HeaderStat(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;
}

/// One colored part of the [AccentProgress] bar; [fraction] is clamped to 0..1.
class ProgressSegment {
  const ProgressSegment(this.fraction, this.color, {this.legend});
  final double fraction;
  final Color color;
  final String? legend;
}

/// Segmented progress bar with a caption (and optional legend) for the card.
class AccentProgress {
  const AccentProgress(this.segments, {required this.caption, this.showLegend = false});
  final List<ProgressSegment> segments;
  final String caption;
  final bool showLegend;
}

/// Joins the non-blank [parts] with ' · '; null when nothing is left, so a
/// missing supplier/number never prints "null" or a dangling separator.
String? headerFooterText(List<String?> parts) {
  final kept = [
    for (final p in parts)
      if (p != null && p.trim().isNotEmpty) p.trim(),
  ];
  return kept.isEmpty ? null : kept.join(' · ');
}

/// The patterned card directly under the AppBar: white → accent tint, two
/// faint circles, a gradient icon tile, then optional stats, footer and
/// progress. Covers every detail/fill header.
Widget accentHeaderCard({
  required double size,
  required AppAccent accent,
  required IconData icon,
  required String label,
  required String title,
  String? code,
  Widget? badge,
  List<HeaderStat> stats = const [],
  String? footer,
  IconData footerIcon = Icons.info_outline_rounded,
  AccentProgress? progress,
  Widget? child,
}) {
  return _patternedCard(
    size,
    accent,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titleRow(size, accent, icon, label, title, code, badge),
        if (stats.isNotEmpty) ...[SizedBox(height: size * 1.4), _statsBox(size, accent, stats)],
        if (footer != null) ...[SizedBox(height: size * 1.1), _footer(size, footerIcon, footer)],
        if (progress != null) ...[SizedBox(height: size * 1.3), _progress(size, accent, progress)],
        if (child != null) ...[SizedBox(height: size * 1.2), child],
      ],
    ),
  );
}

/// One number in the [accentMetricCard], led by an icon tile in its own
/// [accent] gradient.
class HeaderMetric {
  const HeaderMetric(this.label, this.value, {required this.icon, required this.accent});
  final String label;
  final String value;
  final IconData icon;
  final AppAccent accent;
}

/// Summary variant of [accentHeaderCard] for list pages (Products): the same
/// patterned card holding side-by-side [metrics], with no title row, and an
/// optional [footer] line under them.
Widget accentMetricCard({
  required double size,
  required AppAccent accent,
  required List<HeaderMetric> metrics,
  Widget? footer,
}) {
  return _patternedCard(
    size,
    accent,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < metrics.length; i++) ...[
              if (i > 0) SizedBox(width: size * 1.0),
              Expanded(child: _metricTile(size, accent, metrics[i])),
            ],
          ],
        ),
        if (footer != null) ...[SizedBox(height: size * 1.1), footer],
      ],
    ),
  );
}

Widget _metricTile(double size, AppAccent cardAccent, HeaderMetric m) {
  return Container(
    padding: EdgeInsets.all(size * 0.9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(size * 1.3),
      border: Border.all(color: cardAccent.tint(0.16)),
    ),
    child: Row(
      children: [
        Container(
          key: const Key('headerMetricIcon'),
          width: size * 3.4,
          height: size * 3.4,
          decoration: BoxDecoration(
            gradient: m.accent.gradient,
            borderRadius: BorderRadius.circular(size * 1.0),
            boxShadow: [BoxShadow(color: m.accent.base.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Icon(m.icon, color: Colors.white, size: size * 1.7),
        ),
        SizedBox(width: size * 0.9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.overline(size, color: Colors.grey.shade600, weight: FontWeight.w700),
              ),
              SizedBox(height: size * 0.2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(m.value, maxLines: 1, style: AppTextStyle.h4(size, color: navyDark, weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// White → accent-tint card with two faint circles, shared by the header and
/// metric cards.
Widget _patternedCard(double size, AppAccent accent, Widget child) {
  final radius = BorderRadius.circular(size * 1.7);
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: radius,
      border: Border.all(color: accent.tint(0.18)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Colors.white, accent.tint(0.11)],
        stops: const [0, 0.45, 1],
      ),
      boxShadow: [BoxShadow(color: accent.base.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 6))],
    ),
    child: ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          Positioned(right: -size * 3.4, top: -size * 4, child: decorCircle(size * 11, accent.tint(0.09))),
          Positioned(
            right: size * 4,
            top: size * 3.5,
            child: decorCircle(size * 7, accent.light.withValues(alpha: 0.12)),
          ),
          Padding(padding: EdgeInsets.all(size * 1.6), child: child),
        ],
      ),
    ),
  );
}

Widget _titleRow(
  double size,
  AppAccent accent,
  IconData icon,
  String label,
  String title,
  String? code,
  Widget? badge,
) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: size * 4.4,
        height: size * 4.4,
        decoration: BoxDecoration(gradient: accent.gradient, borderRadius: BorderRadius.circular(size * 1.3)),
        child: Icon(icon, color: Colors.white, size: size * 2.2),
      ),
      SizedBox(width: size * 1.2),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.overline(size, color: accent.text, weight: FontWeight.w600),
            ),
            SizedBox(height: size * 0.2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.h5(size, color: navyDark, weight: FontWeight.w700),
            ),
            if (code != null && code.isNotEmpty) ...[
              SizedBox(height: size * 0.4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: size * 0.7, vertical: size * 0.2),
                decoration: BoxDecoration(color: accent.tint(0.1), borderRadius: BorderRadius.circular(size * 0.6)),
                child: Text(
                  code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.custom(size, scale: 1.0, weight: FontWeight.w600, color: accent.text),
                ),
              ),
            ],
          ],
        ),
      ),
      if (badge != null) ...[
        SizedBox(width: size * 0.8),
        ConstrainedBox(constraints: BoxConstraints(maxWidth: size * 12), child: badge),
      ],
    ],
  );
}

Widget _statsBox(double size, AppAccent accent, List<HeaderStat> stats) {
  return Container(
    padding: EdgeInsets.symmetric(vertical: size * 1.0, horizontal: size * 0.4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(size * 1.2),
      border: Border.all(color: accent.tint(0.14)),
    ),
    child: IntrinsicHeight(
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) VerticalDivider(width: size * 0.8, thickness: 1, color: accent.tint(0.14)),
            Expanded(
              child: Column(
                children: [
                  Text(stats[i].label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyle.small(size)),
                  SizedBox(height: size * 0.2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      stats[i].value,
                      maxLines: 1,
                      style: AppTextStyle.h5(size, weight: FontWeight.w700, color: stats[i].color ?? navyDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _footer(double size, IconData icon, String text) {
  return Row(
    children: [
      Icon(icon, size: size * 1.4, color: Colors.grey.shade600),
      SizedBox(width: size * 0.6),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.small(size, color: Colors.grey.shade700),
        ),
      ),
    ],
  );
}

Widget _progress(double size, AppAccent accent, AccentProgress progress) {
  // Clamp each segment and cap the running total at 1 so an over-filled line
  // or a zero expected qty never overflows the track.
  var used = 0.0;
  final parts = <(double, Color)>[];
  for (final s in progress.segments) {
    final f = math.min(s.fraction.isNaN ? 0.0 : s.fraction.clamp(0.0, 1.0), 1 - used);
    used += f;
    parts.add((f, s.color));
  }
  final legends = progress.segments.where((s) => s.legend != null);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: Container(
          key: const Key('accentProgressTrack'),
          height: size * 0.6,
          color: accent.tint(0.14),
          child: LayoutBuilder(
            builder: (_, c) => Row(
              children: [
                for (final (f, color) in parts)
                  SizedBox(
                    width: c.maxWidth * f,
                    child: ColoredBox(key: const Key('accentProgressSegment'), color: color),
                  ),
              ],
            ),
          ),
        ),
      ),
      SizedBox(height: size * 0.7),
      Row(
        children: [
          Expanded(
            child: Text(
              progress.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.small(size, color: Colors.grey.shade700),
            ),
          ),
          if (progress.showLegend)
            for (final s in legends) ...[
              SizedBox(width: size * 0.8),
              Container(
                width: size * 0.7,
                height: size * 0.7,
                decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
              ),
              SizedBox(width: size * 0.3),
              Text(s.legend!, style: AppTextStyle.small(size)),
            ],
        ],
      ),
    ],
  );
}
