import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/size_config.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../controllers/dispatch_detail_controller.dart';

class TableDetailView extends GetView<DispatchDetailController> {
  const TableDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    double size = SizeConfig.defaultSize;
    return Column(
      children: [
        Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [HexColor("#4682A9"), HexColor("#4682A9")],
              ),
            ),
            height: size * 5,
            width: Get.width,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("#${controller.title}",
                      style: TextStyle(
                          fontSize: size * 1.2,
                          color: Colors.white70,
                          overflow: TextOverflow.ellipsis)),
                  Text("PT.Mcquay Tritungal Pratama",
                      style: TextStyle(
                          fontSize: size * 1.2,
                          color: Colors.white,
                          overflow: TextOverflow.ellipsis)),
                  Row(
                    children: [
                      Icon(Icons.calendar_month,
                          color: Colors.white70, size: size * 1.2),
                      SizedBox(width: size * 0.5),
                      Text("27 Apr 23",
                          style: TextStyle(
                              fontSize: size * 1.2,
                              color: Colors.white70,
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            )),
        Expanded(
          child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 600,
              columns:  [
                DataColumn2(
                  label: Text('Name',style: TextStyle(fontSize:size*1.2),),
                  fixedWidth: size *10
                ),
                DataColumn2(
                  label: Text('Price',style: TextStyle(fontSize:size*1.2)),
                  fixedWidth: size *8
                ),
                DataColumn2(
                  label: Text('Qty',style: TextStyle(fontSize:size*1.2)),
                  fixedWidth: size *4

                ),
                DataColumn2(
                  fixedWidth: size *11,
                  label: Center(child: Text('Scan',style: TextStyle(fontSize:size*1.2))),
                ),
              ],
              rows: controller.exampleRow(size)),
        ),
      ],
    );
  }
}
