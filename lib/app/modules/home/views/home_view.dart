import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../../global/functions.dart';
import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../controllers/home_controller.dart';
import 'clip/wave_clip.dart';
import 'widgets/menu_grid.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String userName = controller.getName();
    final String userRoles = controller.getRoles();
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        // toolbarHeight: size *3.8,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: size * 2),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Center(
                child: IconButton(
                  onPressed: () {
                    Get.bottomSheet(
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.info,
                                  color: Color(0xff2D6187)),
                              title: const Text("Account Info"),
                              onTap: () {
                                Get.back(); // close sheet
                                Get.defaultDialog(
                                  title: "Account Detail",
                                  middleText: "Your logged in as:\n $userName",
                                );
                              },
                            ),
                            ListTile(
                              leading:
                                  const Icon(Icons.logout, color: Colors.red),
                              title: const Text("Logout"),
                              onTap: () {
                                Get.back(); // close sheet
                                controller.logout();
                                infoAlertBottom(
                                    title: "Logout",
                                    "You have been logged out");
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.account_circle_rounded,
                    color: Color(0xff2D6187),
                  ),
                ),
              ),
            ),
          )
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [hex1, hex5])),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: size * 2),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: size * 11),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Dashboard",
                              style:theme.textTheme.titleLarge
                            ),
                            Row(
                              children: [
                                Icon(Icons.home,size: size * 1.7,
                                ),
                                SizedBox(width: size * 1),
                                Text("/ Dashboard",style:theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: size * 2),
                        Container(
                          height: size * 24,
                          width: Get.width,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(size * 1.6),
                            gradient: LinearGradient(
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                              colors: [
                                HexColor("#5db7f5"),
                                HexColor("#8adbca")
                              ],
                            ),
                          ),
                          child: Column(children: [
                            Padding(
                              padding: EdgeInsets.all(size * 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          color: Colors.white, size: size * 2),
                                      SizedBox(width: size * 1),
                                      Obx(() => Text(
                                          formatTime(
                                              controller.currentTime.value),
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: size * 1.2))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Image.asset(
                              "assets/images/logo_short.png",
                              height: size * 5,
                              width: size * 5,
                            ),
                            SizedBox(height: size * 1),
                            Text(
                              controller.getGreeting(),
                              style:theme.textTheme.titleLarge?.copyWith(color: Colors.white70)
                            ),
                            Text(
                              userName,
                              style:theme.textTheme.titleMedium?.copyWith(color: Colors.white70)
                            ),
                            Text("Role : $userRoles",style:theme.textTheme.titleMedium?.copyWith(color: Colors.white70)),
                          ]),
                        ),
                        SizedBox(height: size * 2),
                        GridView.extent(
                          maxCrossAxisExtent: size * 15,
                          crossAxisSpacing: size * 2,
                          mainAxisSpacing: size * 2,
                          shrinkWrap:
                              true, // Important to use with SingleChildScrollView
                          physics:
                              const NeverScrollableScrollPhysics(), // Disable GridView's scrolling
                          children: [
                            MenuGrid(
                              size: size,
                              hex1: '#124076',
                              hex2: '#7F9F80',
                              iconData: CupertinoIcons.briefcase_fill,
                              status: '',
                              title: 'PRODUCT',
                              onTap: controller.goToProductPage,
                            ),
                            MenuGrid(
                              size: size,
                              hex1: '#4A70A9',
                              hex2: '#8FABD4',
                              iconData: CupertinoIcons.bag_badge_plus,
                              status: '0',
                              title: 'RECEIVE ORDER',
                              onTap: controller.goToReceiveOrderHomePage,
                            ),
                            MenuGrid(
                              size: size,
                              hex1: '#FF6F3C',
                              hex2: '#e68d40',
                              iconData: CupertinoIcons.bag_badge_minus,
                              status: '33',
                              title: 'OUTFLOW ORDER',
                              onTap: controller.goToOutflowOrderHomePage,
                            ),
                            MenuGrid(
                              size: size,
                              hex1: '#1679AB',
                              hex2: '#5DEBD7',
                              iconData: CupertinoIcons.backward_end,
                              status: '33',
                              title: 'TEST RETURN',
                              onTap: controller.goToReturnPage,
                            ),
                          ],
                        ),
                        SizedBox(height: size * 2),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                height: size * 4,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                      hex1,
                      hex5,
                    ])),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'Selamat Datang di ',
                      style: TextStyle(
                          fontSize: size * 1.3, color: Colors.black87),
                      children: const <TextSpan>[
                        TextSpan(
                            text: 'Inventory Mastercool',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            children: <Widget>[
              ClipPath(
                clipper: WaveClip(),
                child: Container(
                    padding: EdgeInsets.symmetric(horizontal: size * 2),
                    height: size * 9.5,
                    width: Get.width,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                            colors: [hex1, hex5])),
                    child: Column(
                      children: [
                        Container(
                          width: Get.width - (size * 20),
                          height: size * 6,
                          decoration: BoxDecoration(
                            color:
                                Colors.white, // Set a default color if you want
                            borderRadius: BorderRadius.circular(
                                size * 1), // Optional: Add border radius
                          ),
                          child: Image.asset(
                            "assets/images/inventory_logo.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
