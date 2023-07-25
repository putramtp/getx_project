import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../controllers/dispatch_controller.dart';
import '../source/table_dispatch_datasource.dart';

class TableView extends GetView<DispatchController> {
  final double size;

  const TableView({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => controller.listDispatch.isNotEmpty
        ? SfDataGridTheme(
            data: SfDataGridThemeData(
                // headerColor: HexColor("#F2EE9D"),
                gridLineColor: HexColor("#F9F54B"),
                gridLineStrokeWidth: 2),
            child: Obx(
              () => SfDataGrid(
                source: DispatchDataSource(receives: controller.listDispatch,onTap:controller.onTapCellNo,size:size),
                allowSorting: true,
                columnWidthMode: ColumnWidthMode.lastColumnFill,
                columns: [
                    GridColumn(
                    columnName: 'No',
                    width: size *9,
                    label: Container(
                        alignment: Alignment.center,
                        child:  Text(
                          'No',
                          softWrap: false,
                           style: TextStyle(fontSize: size*1.2),
                        ))),
                  GridColumn(
                      columnName: 'Date',
                      width: size *8,
                      label: Container(
                          alignment: Alignment.centerLeft,
                          child:  Text(
                            'Date',
                            softWrap: false,
                            style: TextStyle(fontSize: size*1.2),
                          ))),
                  GridColumn(
                      columnName: 'Suplier',
                      width: size *14,
                      label: Container(
                          alignment: Alignment.centerLeft,
                          child:  Text(
                            'Suplier',
                            softWrap: false,
                            style: TextStyle(fontSize: size *1.2),
                          ))),
                  GridColumn(
                      columnName: 'Jumlah',
                      label: Container(
                          alignment: Alignment.center,
                          child:  Text(
                            'Qty',
                            softWrap: false,
                            style: TextStyle(fontSize: size *1.2),
                          ))),
                          
                ],
              ),
            ),
          )
        : Center(child:  Text("There are no data available yet.",style:TextStyle(fontSize: size * 1.6,color: Colors.red[300]),)));
  }
}
