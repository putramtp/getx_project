import 'package:flutter/material.dart';

class NotFoundImage extends StatelessWidget {
  final double height;
  final double width;
  final String path ;
  const NotFoundImage({super.key, required this.height, required this.width,required this.path});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Image.asset(path,
      width: width,
      height: height,
    ));
  }
}
