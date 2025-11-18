
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../../global/functions.dart';
import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../controllers/home_controller.dart';
import 'clip/wave_clip.dart';
import 'widgets/menu_grid.dart';
import 'widgets/menu_list.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final String userName =  controller.getName();
    final String userRoles =  controller.getRoles();
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: AppBar(
        // toolbarHeight: size *3.8,
        actions: [Padding(
          padding:  EdgeInsets.only(right: size *2),
         child: CircleAvatar(
  backgroundColor: Colors.white,
  child: Center(
    child: IconButton(
      onPressed: () {
        Get.bottomSheet(
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.info, color: Color(0xff2D6187)),
                  title: const Text("Account Info"),
                  onTap: () {
                    Get.back(); // close sheet
                    Get.defaultDialog(
                      title: "Account Detail",
                      middleText: "Your logged in as:\n $userName",
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Logout"),
                  onTap: () {
                    Get.back(); // close sheet
                    controller.logout();
                    infoAlertBottom(title:"Logout", "You have been logged out");
                  },
                ),
              ],
            ),
          ),
        );
      },
      icon: const Icon(
        Icons.account_circle_rounded,
        color: Color(0xff2D6187),
      ),
    ),
  ),
),

        )],
        flexibleSpace: Container(decoration: BoxDecoration(gradient:LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors:  [hex1,hex5])),),
      ),
      body: Stack(
        children: [
              Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: size * 2),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: size * 10),  
                          Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 125, 154, 216), // Set a default color if you want
                                borderRadius: BorderRadius.circular(10), // Optional: Add border radius
                              ),
                              child: ListTile(
                                onTap: controller.goToInventoryPage,
                                  leading: const Icon(CupertinoIcons.cube_box_fill,color:Colors.white70),
                                  title:Text("Inventory",style:TextStyle(fontWeight: FontWeight.w500,fontSize: size*2.2,color:Colors.white),) ,
                                  trailing: const CircleAvatar(backgroundColor: Color(0xff6C9BCF), child:  Icon(Icons.chevron_right_rounded,color: Colors.white70)),
                              ),
                          ),
                          SizedBox(height: size * 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Dashboard",style: TextStyle(fontWeight: FontWeight.bold,fontSize: size*2),),
                              Row(
                                children: [
                                  Icon(Icons.home,size: size*2,),
                                  SizedBox(width: size*1),
                                  Text("/ Dashboard",style: TextStyle(fontWeight: FontWeight.bold,fontSize: size*1.2),),
                                ],
                              ),
                  
                            ],
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
                                Text("God Morning $userName",style:TextStyle(color:Colors.white,fontWeight: FontWeight.bold,fontSize: size *2.2)),
                                Text("Your Role : $userRoles",style:TextStyle(color:Colors.white60,fontWeight: FontWeight.w700,fontSize: size *1.3,letterSpacing:1)),
                              
                              ]
                            ),
                          ),
                          SizedBox(height: size *2),
                          GridView.extent(
                            maxCrossAxisExtent: size * 15,
                            crossAxisSpacing: size *2,
                            mainAxisSpacing: size *2,
                            shrinkWrap: true, // Important to use with SingleChildScrollView
                            physics: const NeverScrollableScrollPhysics(), // Disable GridView's scrolling
                          children: [
                            MenuGrid(size: size,hex1: '#124076',hex2: '#7F9F80',iconData: CupertinoIcons.bag_badge_plus,status: '0',title: 'Receive Order',onTap:controller.goToReceiveOrderHomePage),
                            MenuGrid(size: size,hex1: '#85193C',hex2: '#D76C82',iconData: CupertinoIcons.bag_badge_minus,status: '33',title: 'Outflow Order',onTap:controller.goToOutflowOrderHomePage),
                            MenuGrid(size: size,hex1: '#4A70A9',hex2: '#8FABD4',iconData: CupertinoIcons.chevron_back,status: '33',title: 'Return Order',onTap: controller.goToReturnPage),
                          ],),
                          SizedBox(height: size *2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("History",style: TextStyle(fontWeight: FontWeight.bold,fontSize: size*2),),
                              Row(
                                children: [
                                  Icon(CupertinoIcons.clock_fill,size: size*2,),
                                  SizedBox(width: size*1),
                                  Text("/ History",style: TextStyle(fontWeight: FontWeight.bold,fontSize: size*1.2),),
                                ],
                              ),
                  
                            ],
                          ),
                          SizedBox(height: size * 2),
                          ListView(
                            shrinkWrap: true,
                            physics: const  NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal:size*2),
                            children: [
                              MenuList(size: size, title: 'Receive Items', onTap: () {},),
                              MenuList(size: size, title: 'Return Items', onTap: () {},),
                              MenuList(size: size, title: 'Receive Items', onTap: () {},),
                            ],
                          ),
                          SizedBox(height: size *2),
                  
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  height: size * 4,
                  decoration: BoxDecoration(
                    gradient:LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                      hex1,
                      hex5,
                    ])
                  ),
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
                                  fontStyle: FontStyle.italic,)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          Column(
            children: <Widget>[
              ClipPath(
                 clipper:WaveClip(),
                 child: Container(
                  padding: EdgeInsets.symmetric(horizontal: size * 2),
                  height: size * 9.5,
                  width: Get.width,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [hex1, hex5])),
                  child: Column(
                    children: [
                      Container(
                        width: Get.width - (size *20),
                        height: size *6,
                        decoration: BoxDecoration(
                          color:  Colors.white, // Set a default color if you want
                          borderRadius: BorderRadius.circular(size*1), // Optional: Add border radius
                        ),
                        child: Image.asset(
                          "assets/images/inventory_logo.png",
                          fit: BoxFit.contain,
                          
                        ),
                      ),
                    ],
                  )
                 ),
               ),
              Container(),
            ],
          ),
      
        ],
      ),
    );
  }
}



