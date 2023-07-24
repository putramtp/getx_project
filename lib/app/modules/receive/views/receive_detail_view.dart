import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../global/size_config.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/stack_body.dart';
import '../controllers/receive_detail_controller.dart';
import 'widgets/table_detail_view.dart';

class ReceiveDetailView extends GetView<ReceiveDetailController> {
  const ReceiveDetailView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
        appBar: AppBar(
          title: titleApp("Detail Receive #${controller.title}", size),
        ),
        body: StackBodyGradient(
        hex1: "#7D7463",
        hex2: "#90AEFF",
        size: size, 
        child: const TableDetailWidget(),

        ));
  }
}
