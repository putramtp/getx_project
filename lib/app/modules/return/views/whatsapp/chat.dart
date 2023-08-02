import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/return_controller.dart';

class Chat extends GetView<ReturnController> {
  final double size;
  const Chat({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          itemCount: 40,
          itemBuilder: (contex,index){
            
          return ListTile(
            minVerticalPadding:size*2,
            leading: CircleAvatar(
                  radius:size * 4, // Set the radius you desire to control the size of the circle
                  child: Image.asset("assets/images/logo_short.png"), // Use an image from assets, or you can use the 'child' property to use an icon or custom widget
                ),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Putra $index",style: TextStyle(fontSize: size*1.3,fontWeight: FontWeight.bold),),
                  ],
                ),
                Text("Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia ",
                style: TextStyle(fontSize: size*1.1),overflow: TextOverflow.ellipsis,),
              ],
            ),  
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("16.30",style: TextStyle(color: const Color.fromARGB(255, 17, 199, 84),fontSize: size*1)),
                SizedBox(height:size * 0.8),
                Container( 
                  width: size*1.5,
                  height: size*1.5,
                  decoration: const BoxDecoration(
                    color:Color.fromARGB(255, 17, 199, 84) ,shape: BoxShape.circle),
                  child: Center(child: Text("1",style: TextStyle(fontSize: size *1,fontWeight: FontWeight.bold,color: Colors.white),))),
              ],
            ),
            
            );
        }),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding:  EdgeInsets.all(size*2),
            child: FloatingActionButton(
              backgroundColor: const  Color(0xff075E54),
              onPressed: (){},child: const Icon(Icons.message_rounded,color: Colors.white,)),
          )),
        
      ],
    );
  }
}