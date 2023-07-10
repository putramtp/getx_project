import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomNavigationBarCostum extends GetView {
  final int index;
  final ValueChanged<int>? onTap ;
  const BottomNavigationBarCostum({
    super.key,
    required this.index,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.grey[100],
      elevation:2,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.bag_badge_plus),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon:  Icon(CupertinoIcons.arrow_down_doc),
          label: 'Receiving Order',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.arrow_up_doc),
          label: 'Return Order',
        ),
      ],
      currentIndex: index,
      selectedItemColor: Colors.blue[700],
      unselectedItemColor: Colors.black,
      onTap: onTap,
    );
  }
}