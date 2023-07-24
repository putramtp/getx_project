import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import 'receive_model.dart';


class ReceiveDetailDataSource extends DataGridSource {
  final List<Receive> receives;
  final ValueChanged<String>? onTap;
  ReceiveDetailDataSource({required this.receives ,required this.onTap}) {
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
                      ))
                  : Text(
                      dataGridCell.value.toString(),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,

                    ));
        }).toList());
  }
}
