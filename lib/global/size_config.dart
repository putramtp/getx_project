import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SizeConfig {
  static late MediaQueryData _mediaQueryData;
  static late Orientation _orientation;

  static late double screenWidth;
  static late double screenHeight;
  static late double defaultSize;


  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    _orientation    = _mediaQueryData.orientation;
    screenWidth     = _mediaQueryData.size.width;
    screenHeight    = _mediaQueryData.size.height;
   
    defaultSize = _orientation == Orientation.landscape
        ? screenHeight * 0.024
        : screenWidth * 0.024;
  }

  static Orientation getOrientation() {
    return _orientation;
  }
}
