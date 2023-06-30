import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/list_view_controller.dart';

class ListViewView extends GetView<ListViewController> {
  const ListViewView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('ListView'),
          centerTitle: true,
        ),
        body: Obx(() {
          final data = controller.listPost;
          if (data.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Column(
              children: [
                ElevatedButton(onPressed: () {
                  controller.test();
                }, child: const Text("Test")),
                Expanded(
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      return ListTile(
                        title: Text(item.title.toString()),
                        subtitle: Text(item.body.toString()),
                        // Add other widget components as needed
                      );
                    },
                  ),
                ),
              ],
            );
          }
        }));
  }
}
