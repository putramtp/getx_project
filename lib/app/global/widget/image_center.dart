import 'package:flutter/material.dart';

class ImageCenter extends StatelessWidget {
  final double height;
  final double width;
  final String path ;
  final Widget desc;
   
  const ImageCenter({super.key, required this.height, required this.width,required this.path,required this.desc});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            path,
            width: width,
            height: height,
          ),
          desc
        ],
      ),
    );
  }
}
