import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImageCenter extends GetView {
  final double height;
  final double width;
  final String path ;
  const ImageCenter({super.key, required this.height, required this.width,required this.path});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Image.asset(path,
      width: width,
      height: height,
    ));
  }
}
