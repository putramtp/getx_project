import 'package:flutter/material.dart';

class AppTextStyle {
  AppTextStyle._();

  /// 🔹 HEADINGS
  static TextStyle h1(double size,
      {Color color = Colors.black,
      FontWeight weight = FontWeight.bold}) {
    return TextStyle(
      fontSize: size * 2.6,
      fontWeight: weight,
      color: color,
      height: 1.2,
    );
  }

  static TextStyle h2(double size,
      {Color color = Colors.black,
      FontWeight weight = FontWeight.bold}) {
    return TextStyle(
      fontSize: size * 2.3,
      fontWeight: weight,
      color: color,
      height: 1.25,
    );
  }

  static TextStyle h3(double size,
      {Color color = Colors.black,
      FontWeight weight = FontWeight.w600}) {
    return TextStyle(
      fontSize: size * 2.0,
      fontWeight: weight,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle h4(double size,
      {Color color = Colors.black,
      FontWeight weight = FontWeight.w600}) {
    return TextStyle(
      fontSize: size * 1.8,
      fontWeight: weight,
      color: color,
      height: 1.35,
    );
  }

  static TextStyle h5(double size,
      {Color color = Colors.black,
      FontWeight weight = FontWeight.w500}) {
    return TextStyle(
      fontSize: size * 1.6,
      fontWeight: weight,
      color: color,
      height: 1.4,
    );
  }

  /// 🔹 BODY
  static TextStyle body(double size,
      {Color color = Colors.black87}) {
    return TextStyle(
      fontSize: size * 1.2,
      color: color,
      height: 1.5,
    );
  }

  static TextStyle bodyBold(double size,
      {Color color = Colors.black87,weight = FontWeight.w600}) {
    return TextStyle(
      fontSize: size * 1.2,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.5,
    );
  }

  static TextStyle small(double size,
      {Color color = Colors.grey}) {
    return TextStyle(
      fontSize: size * 1.0,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle info(double size,
      {Color color = Colors.black}) {
    return TextStyle(
      fontSize: size * 1.3,
      color: color,
      height: 1.4,
    );
  }
  
  static TextStyle infoBold(double size,
      {Color color = Colors.black,
      FontWeight weight = FontWeight.w500}) {
    return TextStyle(
      fontSize: size * 1.3,
      fontWeight: weight,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle overline(double size,
      {Color color = Colors.grey,
      FontWeight weight = FontWeight.w500}) {
    return TextStyle(
      fontSize: size * 1.0,
      letterSpacing: 1.2,
      fontWeight: weight,
      color: color,
    );
  }

  /// 🔹 STATUS
  static TextStyle success(double size) {
    return TextStyle(
      fontSize: size * 1.3,
      color: Colors.green,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle error(double size) {
    return TextStyle(
      fontSize: size * 1.3,
      color: Colors.red,
      fontWeight: FontWeight.w600,
    );
  }

  /// 🔹 ICON + TEXT
  static TextStyle iconText(double size,
      {Color color = Colors.black54}) {
    return TextStyle(
      fontSize: size * 1.3,
      color: color,
    );
  }
}
