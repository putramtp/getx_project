import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../global/size_config.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/stack_body.dart';
import '../controllers/dispatch_detail_controller.dart';
import 'widgets/table_detail_view.dart';

class DispatchDetailView extends GetView<DispatchDetailController> {
  const DispatchDetailView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
        appBar: AppBar(
          title: titleApp("Detail Dispatch #${controller.title}", size),
        ),
        body: StackBodyGradient(
        hex1: "#61677A",
        hex2: "#272829",
        size: size, 
        child: const TableDetailView(),

        ));
  }
}
