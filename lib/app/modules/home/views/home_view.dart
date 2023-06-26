import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomeView'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'HomeView is working',
              style: TextStyle(fontSize: 20),
            ),
            Obx(() => Text(
                  'Countter : ${controller.count}',
                  style: const TextStyle(fontSize: 20),
                )),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: Colors.teal,
                ),
                onPressed: () {
                  controller.cobaDialog();
                },
                child: const Text('Show AlertDialog')),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 20),
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: Colors.teal,
                  ),
                  child: const Row(
                    children: [
                      Spacer(),
                      Text("Go to next screen"),
                      SizedBox(
                        width: 20,
                      ),
                      Expanded(
                          child: Icon(
                        Icons.arrow_right_alt,
                        size: 40,
                      ))
                    ],
                  ),
                  onPressed: () {
                    Get.toNamed("/login");
                  }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            controller.increment();
          }),
    );
  }
}
