import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:get/get.dart';


class DataItem {
  final String name;
  String value;
  DataItem({required this.name, required this.value});
}

class DispatchDetailController extends GetxController {
  final String title = Get.arguments["title"];
  String  barcodeScanResult = " ";
  
  // @override
  // void onInit() {
  //   super.onInit();
    
  // }



  Future<void> scanBarcode(ChartModel chart,double size) async {
    barcodeScanResult = "";
    try {
      barcodeScanResult = await FlutterBarcodeScanner.scanBarcode( '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      if (barcodeScanResult.isNotEmpty){
          dialogSaveScanning(chart, barcodeScanResult,size ); 
      }
    } catch (e) {
      barcodeScanResult = "";
    }
  }


  List<DataRow> exampleRow(double size ){
    List<DataRow> listDataRow =[
      rawDataRow(ChartModel(id:1 ,isHaveScan: false, title: 'Ac Spit duct',price:20000 ,quantity:20),size),
      rawDataRow(ChartModel(id:2 ,isHaveScan: false, title: 'Ac Spit duct',price:42000 ,quantity:20),size),
      rawDataRow(ChartModel(id:3 ,isHaveScan: true, title: 'Ac Spit duct',price:212000 ,quantity:20),size),
      rawDataRow(ChartModel(id:4 ,isHaveScan: false, title: 'Ac Spit duct',price:88200 ,quantity:20),size),
    ] ;
    return listDataRow;
  }


  DataRow rawDataRow(ChartModel chart ,double size) {
    return DataRow(cells: [
      DataCell(Text(chart.title,style: TextStyle(fontSize:size*1.2))),
      DataCell(Text(chart.price.toString(),style: TextStyle(fontSize:size*1.2))),
      DataCell(Text(chart.quantity.toString(),style: TextStyle(fontSize:size*1.2))),
      DataCell(Center(
            child: !chart.isHaveScan
                ? IconButton(
                    onPressed: () => scanBarcode(chart, size),
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.blue[400],
                      size: size * 2,
                    ))
                : Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.grey[400],
                      size: size * 2,
                    ))
      )
    ]);
  }


  void dialogSaveScanning(ChartModel chart ,String resultScan,double size) {
    Get.defaultDialog(
      title: "",
      content: Column(
        children: [   
          Icon(CupertinoIcons.barcode,size:size *8),
          RichText(
            text: TextSpan(text:"Your scanned is :",style: TextStyle(fontSize: size *1.4,color: Colors.black,fontWeight: FontWeight.bold) ,children:[
               TextSpan(text:resultScan,style:TextStyle(fontSize: size*1.4,color: Colors.blue, fontWeight: FontWeight.bold)),
            ]),  
          ),
          SizedBox(height: size *1),
          Text("Do you want to save this barcode to ",style: TextStyle(fontSize: size *1.4)), 
          Text( "${chart.title} ?",style: TextStyle(fontSize: size *1.4,fontWeight: FontWeight.bold,color:Colors.blue)),
      ],),
      actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: () {
                Get.back();
           
              }
              ,child: const Text("Cancel")),
              SizedBox(width:size*2),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.snackbar("", "${chart.id} success",
                    snackPosition: SnackPosition.BOTTOM,
                    titleText:  Text(
                      "Status",
                      style: TextStyle(color: Colors.green,fontSize: size * 1.6),
                    ),
                  );
                },
                child: const Text("save"),
              ),
            ],
          )
        ] 
    
      
    );
  }


  // @override
  // void onReady() {
  //   super.onReady();
  // }

  // @override
  // void onClose() {
  //   super.onClose();
  // }
  
}



//https://dummyjson.com/carts/1
class ChartModel {
  final int? id;
  final String title;
  final bool isHaveScan;
  int? price;
  int? quantity;


  ChartModel(
      {
      required this.isHaveScan,
      required this.id,
      required this.title,
      this.price,
      this.quantity,
    });
}





