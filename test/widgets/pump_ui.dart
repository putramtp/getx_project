import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/size_config.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pumps [home] inside a GetMaterialApp on a phone-sized view ([width] × 800 dp)
/// with [SizeConfig.defaultSize] set the way `MyApp` sets it.
Future<void> pumpUi(WidgetTester t, Widget home, {double width = 400}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  t.view.physicalSize = Size(width, 800);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  SizeConfig.defaultSize = width * 0.024;
  await t.pumpWidget(GetMaterialApp(home: home));
}
