import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getx_project/app/data/providers/api_providers.dart';
import 'package:getx_project/app/services/auth_service.dart';
import 'package:getx_project/app/services/network_service.dart';

import 'app/global/size_config.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(); // ✅ REQUIRED
  Get.put(AuthService(), permanent: true);
  Get.put(ApiProvider(), permanent: true);
  Get.put(NetworkService(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Warehouse App",
        theme: ThemeData(
            textTheme: TextTheme(
              headlineLarge: TextStyle(fontSize: SizeConfig.fontSize(2.5),fontWeight: FontWeight.bold,),
              headlineMedium: TextStyle(fontSize: SizeConfig.fontSize(2.3),fontWeight: FontWeight.bold),
              headlineSmall: TextStyle(fontSize: SizeConfig.fontSize(2),fontWeight: FontWeight.bold),
              titleLarge: TextStyle(
                fontSize: SizeConfig.fontSize(2.1),
                fontWeight: FontWeight.bold,
              ),
              titleMedium: TextStyle(fontSize: SizeConfig.fontSize(1.7)),
              bodyLarge: TextStyle(fontSize: SizeConfig.fontSize(1.5)),
              bodyMedium: TextStyle(fontSize: SizeConfig.fontSize(1.3)),
              bodySmall: TextStyle(fontSize: SizeConfig.fontSize(1.2)),
            ),
            useMaterial3: true,
            primaryColor: const Color(0xff90AEFF),
            primaryColorLight: const Color(0xffF9F7F7),
            primaryColorDark: const Color(0xff2D6187),
            appBarTheme: const AppBarTheme(
                backgroundColor: Color.fromARGB(255, 134, 157, 207),
                iconTheme: IconThemeData(color: Colors.white)),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              elevation: 0.8,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.black45,
              backgroundColor: const Color.fromARGB(255, 134, 157, 207),
              selectedIconTheme:
                  IconThemeData(color: Colors.white, size: size * 2.5),
              unselectedIconTheme:
                  IconThemeData(color: Colors.black45, size: size * 2),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Color.fromARGB(255, 84, 123, 206))),
        initialRoute: AppPages.homePage,
        getPages: AppPages.routes);
  }
}
