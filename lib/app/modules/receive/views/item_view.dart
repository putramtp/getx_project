import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/size_config.dart';

import '../../../global/widget/image_center.dart';
import '../controllers/item_controller.dart';

class ItemView extends GetView<ItemController> {
  const ItemView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: AppBar(
        title:  Text(controller.title),
      ),
      body: controller.obx((data) =>ListView.builder(
        itemCount: data?.length,
        itemBuilder:(context,index){
          final item = data![index];
        return ListTile(title:Text(item.title));
      }),
      onEmpty: ImageCenter(path: 'assets/images/404_image.png',height: size *40,width:size*40),
      onLoading: const Center(child: CircularProgressIndicator()),
      onError: (error) =>Center(child: Text(error.toString()))   
      )
    );
  }
}
