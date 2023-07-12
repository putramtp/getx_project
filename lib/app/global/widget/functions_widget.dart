import 'package:flutter/material.dart';

AppBar costumAppbar(String title) {
  return AppBar(
    title: Text(title),
    centerTitle: true,
    excludeHeaderSemantics: true,
    backgroundColor: Colors.green[100],
    elevation: 2,
  );
}

Widget titleApp(String text, double size) {
  return Text(text,
      style:
          TextStyle(fontSize: size * 1.3, letterSpacing: 0.5, wordSpacing: 2));
}

Widget titleMenu(String text, double size) {
  return Text(text, style: TextStyle(fontSize: size * 1.17));
}
