import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getx_project/app/api_providers.dart';
import 'package:getx_project/app/services/auth_service.dart';
import 'package:getx_project/app/services/network_service.dart';

import 'app/global/size_config.dart';
import 'app/routes/app_pages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(AuthService()); 
  Get.put(ApiProvider()); 
  Get.put(NetworkService());
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
        useMaterial3: true,
        primaryColor: const Color(0xff90AEFF),
        primaryColorLight: const Color(0xffF9F7F7),
        primaryColorDark: const Color(0xff2D6187),
        appBarTheme:  const AppBarTheme(backgroundColor:  Color.fromARGB(255, 134, 157, 207),iconTheme:IconThemeData(color: Colors.white)),
        bottomNavigationBarTheme:  BottomNavigationBarThemeData(
            elevation:0.8,
            selectedItemColor:Colors.white ,
            unselectedItemColor:Colors.black45 ,
            backgroundColor:const Color.fromARGB(255, 134, 157, 207),
            selectedIconTheme: IconThemeData(color: Colors.white,size: size *2.5),
            unselectedIconTheme: IconThemeData(color: Colors.black45,size: size *2),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color.fromARGB(255, 84, 123, 206) )   

      ),
      initialRoute: AppPages.homePage,
      getPages: AppPages.routes
    );
  }
}