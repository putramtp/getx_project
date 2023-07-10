import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/receive_controller.dart';

class ReceiveView extends GetView<ReceiveController> {
  const ReceiveView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Item Categories'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(
                () => TextField(
                  controller:controller.searchController,
                  onChanged: controller.onSearch,
                  decoration: InputDecoration(
                    border: const UnderlineInputBorder(),
                    labelText: 'Search',
                    hintText: 'Search item categories...',
                    suffixIcon: controller.isSearch.value
                        ?  IconButton(onPressed:controller.onCloseSearch, icon: const Icon(Icons.close))
                        : const Icon(Icons.search),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            Expanded(
              child: Obx(() => controller.filteListCategories.isNotEmpty ? ListView.builder(
                  itemCount: controller.filteListCategories.length,
                  itemBuilder: (BuildContext context, int index) {
                    var item = controller.filteListCategories[index];
                    return ListTile(
                      leading: const Icon(Icons.arrow_right),
                      trailing: const Text(
                        "Go",
                        style: TextStyle(color: Colors.green, fontSize: 15),
                      ),
                      title: Text(item),
                    );
                  }):const Center(child:Text("Not found Categories ",style: TextStyle(color: Colors.red, fontSize: 15)))
                  
                  ) ,
            )
          ],
        ),
      ),
    );
  }
}
