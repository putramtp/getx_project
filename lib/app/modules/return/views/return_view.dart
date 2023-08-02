// ignore_for_file: prefer_const_constructors

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../global/size_config.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/image_center.dart';
import '../controllers/return_controller.dart';

class ReturnView extends GetView<ReturnController> {
  const ReturnView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: AppBar(
        title: titleApp("Return Items", size),      
      ),
      body: Obx(() => controller.isScannedExist.value
          ? Container(
              padding: EdgeInsets.all(size * 2),
              decoration: BoxDecoration(border: Border.all(width:0.7), borderRadius: BorderRadius.circular(size*2)),
              margin: EdgeInsets.all(size * 2),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text("Detail Items",
                        style: GoogleFonts.robotoSerif(
                            fontSize: size *1.6,
                            fontWeight: FontWeight.bold,
                            letterSpacing: size * 0.4)),
                    Divider(color: Get.theme.primaryColorDark, thickness: size * 0.3),
                    SizedBox(height: size * 3),
                    Form(
                      child: Column(
                        children: [
                          Obx(() => TextFormField(
                                readOnly: true,
                                initialValue: controller.barcodeScanResult.value,
                                style: TextStyle(fontSize: size * 1.4),
                                decoration: InputDecoration(
                                  label: Text("Barcode",
                                      style: TextStyle(fontSize: size * 1.6)),
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.blue)),
                                ),
                              )),
                          SizedBox(height: size * 2),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  initialValue:"2023-07-27",
                                  style: TextStyle(fontSize: size * 1.4),
                                  decoration: InputDecoration(
                                    label: Text("Dispatch Date",
                                        style: TextStyle(fontSize: size * 1.6)),
                                    border: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.blue)),
                                  ),
                                ),
                              ),
                              SizedBox(width: size * 2),
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  initialValue: "2023-10-12",
                                  style: TextStyle(fontSize: size * 1.4),
                                  decoration: InputDecoration(
                                    label: Text("Return  Date",
                                        style: TextStyle(fontSize: size * 1.6)),
                                    border: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.blue)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: size * 2),
                          TextFormField(
                            readOnly: true,
                            initialValue: "Ac Daikin 1/2 pk Indor",
                            style: TextStyle(fontSize: size * 1.4),
                            decoration: InputDecoration(
                              label: Text("Name Item",
                                  style: TextStyle(fontSize: size * 1.6)),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue)),
                            ),
                          ),
                          SizedBox(height: size * 2),
                          TextFormField(
                            readOnly: true,
                            initialValue: "PT.McQuay Pratama",
                            style: TextStyle(fontSize: size * 1.4),
                            decoration: InputDecoration(
                              label: Text("Suplier",
                                  style: TextStyle(fontSize: size * 1.6)),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: size * 2),
                    FilledButton(
                      style: ButtonStyle(backgroundColor:MaterialStateColor.resolveWith((states) => Colors.lightGreen)),
                      child: Text("Return Item",
                          style: TextStyle(fontSize: size * 1.4,)),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            )
          : ImageCenter(
              path: "assets/images/file_not_found.png",
              height: size * 20,
              width: size * 25,
              desc: Text(
                "No Scan Result .",
                style: GoogleFonts.dancingScript(
                    fontSize: size * 2,
                    wordSpacing: size * 0.2,
                    letterSpacing: size * 0.2,
                    color: Colors.cyan[800]),
              ))),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: size * 1),
        child: FloatingActionButton.extended(
          onPressed: () => controller.scanBarcode(),
          label: Container(
            padding:  EdgeInsets.all(size *1.5),
            child: Column(
              children: [
                Icon(Icons.camera_alt,
                    color: Get.theme.primaryColorLight, size: size * 4),
                Text("SCAN",
                    style: TextStyle(
                        color: Get.theme.primaryColorLight,
                        fontSize: size * 1.2,
                        fontWeight: FontWeight.bold,
                        letterSpacing: size * 0.1)),
              ],
            ),
          ),
          extendedPadding: EdgeInsets.all(size * 1),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
