import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getx_project/app/global/size_config.dart';

import '../../../global/variables.dart';
import '../../../global/widget/image_center.dart';
import '../controllers/home1_controller.dart';

class Home1View extends GetView<Home1Controller> {
  const Home1View({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.fromLTRB(size * 2,size * 2, size * 2,0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              ImageCenter(
                path: 'assets/images/logo.png',
                height: size * 5,
                width: size * 17,
              ),
              SizedBox(height: size * 2),
              Image.asset(
                "assets/images/gedung2.jpeg",
                filterQuality: FilterQuality.high,
                height: size * 15,
                width: size * 42,
                fit: BoxFit.fitWidth,
              ),
              Padding(
                padding: EdgeInsets.only(top: size * 2),
                child: const Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Column(
                      children: [
                        const Icon(CupertinoIcons.bag_badge_plus),
                        Text('Receiving Order',
                            style: TextStyle(fontSize: size * 1.2)),
                      ],
                    ),
                    iconSize: size * 4,
                    onPressed: () {},
                    tooltip: 'Receiving Order',
                  ),
                  IconButton(
                    icon: Column(
                      children: [
                        const Icon(CupertinoIcons.bag_badge_minus),
                        Text('Output Order',
                            style: TextStyle(fontSize: size * 1.2)),
                      ],
                    ),
                    iconSize: size * 4,
                    onPressed: () {},
                    tooltip: 'Output Order',
                  ),
                  IconButton(
                    icon: Column(
                      children: [
                        const Icon(CupertinoIcons.arrow_down_to_line),
                        Text('Return Order',
                            style: TextStyle(fontSize: size * 1.2)),
                      ],
                    ),
                    iconSize: size * 4,
                    onPressed: () {},
                    tooltip: 'Return Order',
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
                    text: 'Inventroy Mastercool',
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
