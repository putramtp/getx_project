import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getx_project/app/global/size_config.dart';

import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      body: Container(
        padding: EdgeInsets.fromLTRB(size * 2, size * 2, size * 2, 0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height:size*3),
              Image.asset(
                "assets/images/inventory_logo.png",
                height: size * 12,
                width: size * 36,
                filterQuality: FilterQuality.high,
                fit: BoxFit.fitWidth,
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Column(
                      children: [
                        const Icon(CupertinoIcons.cube_box,
                            color: Colors.brown),
                        titleMenu("Inventory", size),
                      ],
                    ),
                    iconSize: size * 2.8,
                    onPressed: () {
                      Get.toNamed(AppPages.inventoryPage);
                    },
                    tooltip: 'Inventory',
                  ),
                  IconButton(
                    icon: Column(
                      children: [
                        const Icon(CupertinoIcons.bag_badge_plus,
                            color: Color.fromRGBO(3, 110, 3, 1)),
                        titleMenu("Receiving Item", size),
                      ],
                    ),
                    iconSize: size * 2.8,
                    onPressed: () {
                      Get.toNamed(AppPages.receivePage);
                    },
                    tooltip: 'Receiving Item',
                  ),
                  IconButton(
                    icon: Column(
                      children: [
                        const Icon(CupertinoIcons.bag_badge_minus,
                            color: Color.fromARGB(255, 190, 172, 3)),
                        titleMenu("Output Item", size),
                      ],
                    ),
                    iconSize: size * 2.8,
                    onPressed: () {},
                    tooltip: 'Output Item',
                  ),
                  IconButton(
                    icon: Column(
                      children: [
                        const Icon(
                          CupertinoIcons.arrow_down_to_line,
                          color: Color.fromARGB(255, 243, 122, 114),
                        ),
                        titleMenu("Return Item", size),
                      ],
                    ),
                    iconSize: size * 2.8,
                    onPressed: () {},
                    tooltip: 'Return Item',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: size * 4,
        color: hex1,
        child: Center(
          child: RichText(
            text: TextSpan(
              text: 'Selamat Datang di ',
              style: TextStyle(fontSize: size * 1.3, color: Colors.black87),
              children: const <TextSpan>[
                TextSpan(
                    text: 'Inventory Mastercool',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
