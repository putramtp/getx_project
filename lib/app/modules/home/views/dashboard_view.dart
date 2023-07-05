import 'package:flutter/material.dart';

import 'package:get/get.dart';

class DashboardView extends GetView {
  const DashboardView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return  SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const <DataColumn>[
            DataColumn(
              label: Text(
                'Order ID',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Product',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Quantity',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Price',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: const <DataRow>[
            DataRow(
              cells: <DataCell>[
                DataCell(Text('1')),
                DataCell(Text('Product A')),
                DataCell(Text('2')),
                DataCell(Text('\$20')),
              ],
            ),
            DataRow(
              cells: <DataCell>[
                DataCell(Text('2')),
                DataCell(Text('Product B')),
                DataCell(Text('3')),
                DataCell(Text('\$30')),
              ],
            ),
            DataRow(
              cells: <DataCell>[
                DataCell(Text('3')),
                DataCell(Text('Product C')),
                DataCell(Text('1')),
                DataCell(Text('\$10')),
              ],
            ),
          ],
        ),
      );
  }
}
