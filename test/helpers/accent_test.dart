import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/global/accent.dart';
import 'package:getx_project/app/global/variables.dart';

void main() {
  test('accents map to the spec palette', () {
    expect(AppAccent.sky.text, skyBlueDark);
    expect(AppAccent.amber.text, amberDark);
    expect(AppAccent.sage.text, sageTealDark);
    expect(AppAccent.purple.text, mutedPurple);
    expect(AppAccent.slate.base, navyMid);
    expect(AppAccent.steel.light, lightSteelBlue);
  });

  test('tint applies the requested alpha', () {
    expect(AppAccent.sky.tint().a, closeTo(0.12, 0.01));
    expect(AppAccent.sky.tint(0.2).a, closeTo(0.2, 0.01));
  });

  test('accentFor is deterministic and maps empty to slate', () {
    expect(accentFor('Indo Kemas'), accentFor('Indo Kemas'));
    expect(accentFor(''), AppAccent.slate);
  });

  test('readableOnWhite falls back to navy for light colors', () {
    expect(readableOnWhite(const Color(0xFFFFFFFF)), navyMid);
    expect(readableOnWhite(const Color(0xFFEEEEEE)), navyMid);
    expect(readableOnWhite(steelBlue), steelBlue);
  });
}
