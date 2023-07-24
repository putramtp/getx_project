import 'dart:developer';

import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../views/source/receive_model.dart';

class ReceiveController extends GetxController {
  RxList<Receive> listReceive = <Receive>[].obs;
  RxInt selectedIndex  = 1.obs ;

  @override
  void onInit() {
    // getProduct();
    addDataTable();
    super.onInit();
    
  }

  // @override
  // void onReady() {
  //   super.onReady();
  // }

  // @override
  // void onClose() {
  //   super.onClose();
  // }

  onSelectedBNavigation(int index){
    selectedIndex.value = index;
    switch (selectedIndex.value) {
      case 0:  getDataPreviousWeek();break;
      case 1:  getToday();break;
      case 2:  getDataUpComing();break;
      default:getToday();
    }
  }

   void addDataTable() {
    listReceive.value = setDataToday();
  }

  void getToday() {
    listReceive.value = setDataToday();
  }
  void getDataUpComing() {
    listReceive.value = setDataUpComing();
  }
  void getDataPreviousWeek() {
    listReceive.value = setDataLast();
  }

  onTapCellPO(String stringId){
      log("id :$stringId");
      try {
        Get.toNamed(AppPages.receiveDetailPage,arguments:{"title":stringId});
      } catch (e) {
        log("error: $e");
      }
      
  }
  
  List<Receive> setDataToday() {
    return [
      Receive(10001,"2023-07-20",'PT.James Saturna Indonesia',2),
      Receive(10002,"2023-07-20",'PT.Kathryn Indonesia',3),
      Receive(10003,"2023-07-20",'PT.Lara Lancang', 2),
      Receive(10004,"2023-07-20",'PT.Michael Oke',12),
      Receive(10005,"2023-07-20",'PT.Martin Success',4),
      Receive(10006,"2023-07-20",'PT.Newberry Belle',1),
      Receive(10007,"2023-07-20",'PT.Balnc Xianox',7),
      Receive(10008,"2023-07-20",'PT.Perry Supsia',2),
      Receive(10009,"2023-07-20",'PT.Gable Andrusaa', 1),
    ];
  }
  List<Receive> setDataUpComing() {
    return [];
  }
  List<Receive> setDataLast() {
    return [
      Receive(10008,"2023-07-10", 'PT.Daikin Indonesia',  2),
      Receive(10009,"2023-07-17", 'PT.Sehati Karya',  4),
    ];
  }



}





