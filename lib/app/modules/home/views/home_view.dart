import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../../global/functions.dart';
import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../controllers/home_controller.dart';
import 'widgets/menu_grid.dart';
import 'widgets/menu_drawer.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: size *3.5,
        actions: [Padding(
          padding:  EdgeInsets.only(right: size *2),
          child:  IconButton(onPressed:(){
            Get.defaultDialog(title: "Account Detail",middleText: "This is user Informations");
          }, icon: Icon(Icons.account_circle_outlined,size:size *2)),
        )],
      ),
      drawer: DrawerMenu(size: size),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 2),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Dashboard",style: TextStyle(fontSize: size*2,fontWeight: FontWeight.bold),),
                        const Row(
                          children: [
                            Icon(Icons.home_outlined),
                            Text("/"),
                            Text("Dashboard"),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: size * 2),
                    Center(
                      child: Image.asset(
                        "assets/images/inventory_logo.png",
                        height: size * 10,
                        width: size * 30,

                      ),
                    ),
                    SizedBox(height: size * 2),
                    Container(
                      height: size * 24,
                      width: Get.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(size * 1.6),
                        gradient: LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [HexColor("#78C1F3"), HexColor("#9BE8D8")],
                        ),
                      ),
                      child: Column(
                        children: [
                            Padding(
                              padding:  EdgeInsets.all(size*2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.access_time ,color:Colors.white,size: size*2),
                                      SizedBox(width: size*1),
                                      Obx(() => Text(formatTime(controller.currentTime.value),style:TextStyle(color:Colors.white,fontWeight: FontWeight.bold,fontSize: size *1.2))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          Image.asset(
                            "assets/images/logo_short.png",
                            height: size * 5,
                            width: size *5,
                          ),
                          SizedBox(height: size * 1),
                          Text("God Morning Putra Pardede",style:TextStyle(color:Colors.white70,fontWeight: FontWeight.bold,fontSize: size *2.2)),
                          Text("Your Role : Admin",style:TextStyle(color:Colors.white60,fontWeight: FontWeight.w700,fontSize: size *1.3,letterSpacing:1)),
                        
                        ]
                      ),
                    ),
                    SizedBox(height: size *0.5),
                    GridView.extent(
                      maxCrossAxisExtent: size * 30,
                      padding:  EdgeInsets.all(size *2),
                      crossAxisSpacing: size * 2,
                      mainAxisSpacing: size * 2,
                      shrinkWrap: true, // Important to use with SingleChildScrollView
                      physics: const NeverScrollableScrollPhysics(), // Disable GridView's scrolling
                    children: [
                      MenuGrid(size: size,hex1: '#A8A196',hex2: '#F4E0B9',iconData: CupertinoIcons.cube_box,status: '',title: 'Inventory',onTap:controller.goToInventoryPage),
                      MenuGrid(size: size,hex1: '#4FC0D0',hex2: '#8eeb8a',iconData: CupertinoIcons.bag_badge_plus,status: '33',title: 'Receive Item',onTap:controller.goToReceivePage),
                      MenuGrid(size: size,hex1: '#F97B22',hex2: '#FEE8B0',iconData: CupertinoIcons.bag_badge_minus,status: '0',title: 'Output Item',onTap: () {}),
                      MenuGrid(size: size,hex1: '#FF6666',hex2: '#FCAEAE',iconData: CupertinoIcons.arrow_down_to_line_alt,status: '33',title: 'Output Item',onTap: () {}),
                    ],)
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: size * 4,
            color: hex1,
            child: Center(
              child: RichText(
                text: TextSpan(
                  text: 'Selamat Datang di ',
                  style: TextStyle(fontSize: size * 1.3, color: Colors.black87),
                  children: const <TextSpan>[
                    TextSpan(
                        text: 'Inventory Mastercool',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

