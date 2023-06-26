import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'app/routes/app_pages.dart';

void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Application",
       theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      initialRoute: AppPages.homePage,
      getPages: AppPages.routes
    );
  }
}