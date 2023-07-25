import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import 'dispatch_model.dart';


class DispatchDataSource extends DataGridSource {
  final List<DispatchModel> receives;
  final ValueChanged<String>? onTap;
  final double size;
  DispatchDataSource({required this.receives ,required this.onTap,required this.size}) {
    dataGridRows = receives
        .map<DataGridRow>((dataGridRow) => DataGridRow(cells: [
              DataGridCell<int>(columnName: 'id', value: dataGridRow.id),
              DataGridCell<String>(columnName: 'date', value: dataGridRow.date),
              DataGridCell<String>(columnName: 'suplier', value: dataGridRow.suplier),
              DataGridCell<int>(
                  columnName: 'count', value: dataGridRow.count),
            ]))
        .toList();
  }

  List<DataGridRow> dataGridRows = [];

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    Color getRowBackgroundColor() {
      final int index = effectiveRows.indexOf(row);
      if (index % 2 != 0) {
        return Colors.lime[50]!;
      }

      return Colors.transparent;
    }

    return DataGridRowAdapter(
        color: getRowBackgroundColor(),
        cells: row.getCells().map<Widget>((dataGridCell) {
          return Container(
              alignment: (dataGridCell.columnName == 'id' ||dataGridCell.columnName == 'count') ? Alignment.center: Alignment.centerLeft,
              child: (dataGridCell.columnName == 'id')
                  ? TextButton(
                      onPressed: () {
                          onTap!(dataGridCell.value.toString());
                      },
                      child: Text(
                        dataGridCell.value.toString(),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style:TextStyle(fontSize: size *1.2),
                      ))
                  : Text(
                      dataGridCell.value.toString(),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style:TextStyle(fontSize: size *1.2),

                    ));
        }).toList());
  }
}
