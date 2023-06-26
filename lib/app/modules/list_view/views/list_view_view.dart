import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/list_view_controller.dart';

class ListViewView extends GetView<ListViewController> {
  const ListViewView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ListViewView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'ListViewView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
