  import 'package:flutter/material.dart';


import '../../modules/home/views/receiving_widet.dart';
import '../../modules/home/views/return_widget.dart';
import '../../modules/home/views/category/category_widget.dart';
import 'image_center.dart';

AppBar costumAppbar(String title) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      excludeHeaderSemantics: true,
      backgroundColor: Colors.green[100],
      elevation: 2,
    );
}

 Widget buildContent(int selectedIndex,double sizeDefault) {
    switch (selectedIndex) {
      case 0:
        return const CategoryView();
      case 1:
        return  const ReceivingOrderView();
      case 2:
        return const ReturnOrderView();
      default:
        return  ImageCenter(height:sizeDefault * 24,width:sizeDefault * 24, path: "assets/images/404_Image.png"); // Or return a default content widget
    }
  }
  Widget buildTitle(int selectedIndex,double sizeDefault) {
    switch (selectedIndex) {
      case 0:
        return const Text("Receive Order");
      case 1:
        return  const Text("Receive Order");
      case 2:
        return const Text("Return Order");
      default:
        return const Text("None"); // Or return a default content widget
    }
  }