import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../../global/size_config.dart';
import '../../controllers/return_controller.dart';
import 'chat.dart';

class ReturnView extends GetView<ReturnController> {
  const ReturnView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
    
      appBar: AppBar(
        backgroundColor:const  Color(0xff075E54),
        title:  Text("WhatsApp",style:TextStyle(fontSize: size * 1.8, letterSpacing: 0.5, wordSpacing: 2 ,color:Colors.white)),
        elevation: 0.7,
        actions: [
             const Icon(Icons.camera_alt_outlined,color: Colors.white,),
             SizedBox(width: size*2),
             const Icon(Icons.search,color: Colors.white),
             SizedBox(width: size*2),
             const Icon(Icons.more_vert,color: Colors.white),
             SizedBox(width: size*1),
        ],
        bottom:  TabBar(
          controller: controller.tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor:Colors.white ,
          tabs:   <Widget>[
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Chat"),
                  const SizedBox(width: 5),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(shape: BoxShape.circle,color:Colors.white),
                    child: const Center(child: Text("2",style: TextStyle(color:Color(0xff075E54) ),)))
                ],
              ),
            ),
            const Tab(
              text: "Status",
            ),
            const Tab(
              text: "Panggilan",
            ),
          ],
        ),
      ),
      body:  TabBarView(
         controller: controller.tabController,
        children:  <Widget>[
          Chat(size: size),
          Chat(size: size),
          Chat(size: size),
        ],
      ),
    );
  }
}
