import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyle {
  AppTextStyle._();

  // ── Headings ────────────────────────────────────────────────────

  static TextStyle h1(double size, {Color color = Colors.black, FontWeight weight = FontWeight.bold}) {
    return GoogleFonts.plusJakartaSans(fontSize: size * 2.6, fontWeight: weight, color: color, height: 1.2);
  }

  static TextStyle h2(double size, {Color color = Colors.black, FontWeight weight = FontWeight.bold}) {
    return GoogleFonts.plusJakartaSans(fontSize: size * 2.3, fontWeight: weight, color: color, height: 1.25);
  }

  static TextStyle h3(double size, {Color color = Colors.black, FontWeight weight = FontWeight.w600}) {
    return GoogleFonts.plusJakartaSans(fontSize: size * 2.0, fontWeight: weight, color: color, height: 1.3);
  }

  static TextStyle h4(double size, {Color color = Colors.black, FontWeight weight = FontWeight.w600}) {
    return GoogleFonts.plusJakartaSans(fontSize: size * 1.8, fontWeight: weight, color: color, height: 1.35);
  }

  static TextStyle h5(double size, {Color color = Colors.black, FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.plusJakartaSans(fontSize: size * 1.6, fontWeight: weight, color: color, height: 1.4);
  }

  // ── Body ────────────────────────────────────────────────────────

  static TextStyle body(double size, {Color color = Colors.black87}) {
    return GoogleFonts.plusJakartaSans(fontSize: size * 1.2, color: color, height: 1.5);
  }

  static TextStyle bodyBold(double size, {Color color = Colors.black87, FontWeight weight = FontWeight.w600}) {
    return GoogleFonts.plusJakartaSans(fontSize: size * 1.2, fontWeight: weight, color: color, height: 1.5);
  }

  static TextStyle small(double size, {Color color = Colors.grey}) {
    return GoogleFonts.plusJakartaSans(fontSize: size * 1.0, color: color, height: 1.4);
  }

  static TextStyle info(double size, {Color color = Colors.black}) {
    return GoogleFonts.plusJakartaSans(fontSize: size * 1.3, color: color, height: 1.4);
  }

  static TextStyle infoBold(double size, {Color color = Colors.black, FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.plusJakartaSans(fontSize: size * 1.3, fontWeight: weight, color: color, height: 1.4);
  }

  static TextStyle overline(double size, {Color color = Colors.grey, FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.plusJakartaSans(fontSize: size * 1.0, letterSpacing: 1.2, fontWeight: weight, color: color);
  }

  // ── Status ──────────────────────────────────────────────────────

  static TextStyle success(double size) {
    return GoogleFonts.plusJakartaSans(fontSize: size * 1.3, color: Colors.green, fontWeight: FontWeight.w600);
  }

  static TextStyle error(double size) {
    return GoogleFonts.plusJakartaSans(fontSize: size * 1.3, color: Colors.red, fontWeight: FontWeight.w600);
  }

  // ── Icon + Text ─────────────────────────────────────────────────

  static TextStyle iconText(double size, {Color color = Colors.black54}) {
    return GoogleFonts.plusJakartaSans(fontSize: size * 1.3, color: color);
  }

  // ── Escape hatch ────────────────────────────────────────────────
  // For one-off sizes/weights that don't match a named style above. Still
  // returns Plus Jakarta Sans so all text flows through the design system —
  // prefer a named method when one fits. Pass [scale] for a size-relative
  // value (fontSize = size * scale) or [px] for an absolute pixel size.

  static TextStyle custom(
    double size, {
    double scale = 1.2,
    double? px,
    Color? color,
    FontWeight? weight,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: px ?? size * scale,
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Color/weight-only style with NO font size — the size is inherited from the
  /// surrounding text theme (Plus Jakarta Sans). Use to replace inline
  /// `TextStyle(color: ...)` / `TextStyle(fontWeight: ...)` without forcing a
  /// size (which would change appearance).
  static TextStyle plain({
    Color? color,
    FontWeight? weight,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
