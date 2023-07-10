import 'package:flutter/material.dart';

import 'package:get/get.dart';

class ReturnOrderView extends GetView {
  const ReturnOrderView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return  const Center(
        child: Text(
          'ReturnOrderView is working',
          style: TextStyle(fontSize: 20),
        ),
    );
  }
}
