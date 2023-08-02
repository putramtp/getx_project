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
  return Text(text,style:TextStyle(fontSize: size * 1.8, letterSpacing: 0.5, wordSpacing: 2,color: Colors.white,fontWeight: FontWeight.w500),overflow: TextOverflow.ellipsis,);
}

Widget titleMenu(String text, double size) {
  return Text(text, style: TextStyle(fontSize: size * 1.17));
}

Widget testContainer(double size) {
  return Container(height: size,width: size ,color: Colors.brown);
}
