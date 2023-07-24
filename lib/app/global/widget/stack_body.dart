
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

class StackBodyGradient extends StatelessWidget {
  final Widget child;
  final double size;
  final String hex1;
  final String hex2;
  const StackBodyGradient({super.key,required this.child,required this.size,required this.hex1,required this.hex2});

  @override
  Widget build(BuildContext context) {
    return Stack(
        children: [
            Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [HexColor(hex1), HexColor(hex2)],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(size * 4.5)),
            child: Container(
              margin: EdgeInsets.all(size*1),
              color: Colors.white,
              child:child ),
          ),
        ],
      );
  }
}