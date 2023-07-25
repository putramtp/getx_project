import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../controllers/home_controller.dart';

class DrawerMenu extends GetView<HomeController> {
  const DrawerMenu({
    super.key,
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [HexColor("#78C1F3"), HexColor("#9BE8D8")],
              ),
            ),
            child: Center(
              child: Image.asset(
                "assets/images/logo.png",
                // height: size * 5,
                width: size * 15,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left:size*0.5),
              child: ListView(
                children: [
                  ListTile(
                    leading:Icon(CupertinoIcons.cube_box,size:size*2,color:HexColor("#768275")),
                    title:  Text('Inventory',style: TextStyle(fontSize: size*1.2),),
                    trailing: Icon(CupertinoIcons.arrow_right,size:size*1.4),
                    onTap:controller.goToInventoryPage,
                  ),
                  ListTile(
                    leading:Icon(CupertinoIcons.bag_badge_plus,size:size*2,color:HexColor("#1bbf0d")),
                    title:  Text('Receive Items',style: TextStyle(fontSize: size*1.2),),
                    trailing: Icon(CupertinoIcons.arrow_right,size:size*1.4),
                    onTap:controller.goToInventoryPage,
                  ),
                  ListTile(
                    leading:Icon(CupertinoIcons.bag_badge_minus,size:size*2,color:HexColor("#c4890a")),
                    title:  Text('Dispatch Items',style: TextStyle(fontSize: size*1.2),),
                    trailing: Icon(CupertinoIcons.arrow_right,size:size*1.4),
                    onTap:controller.goToInventoryPage,
                  ),
                  ListTile(
                    leading:Icon(CupertinoIcons.chevron_back,size:size*2,color:HexColor("#f74848")),
                    title:  Text('Return Items',style: TextStyle(fontSize: size*1.2),),
                    trailing: Icon(CupertinoIcons.arrow_right,size:size*1.4),
                    onTap:controller.goToInventoryPage,
                  ),
                ],
                
              ),
            ),
          ),
         
        ],
      ),
    );
  }
}
