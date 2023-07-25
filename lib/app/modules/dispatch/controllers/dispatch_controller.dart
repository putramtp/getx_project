import 'dart:developer';

import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../views/source/dispatch_model.dart';

class DispatchController extends GetxController {
  RxList<DispatchModel> listDispatch = <DispatchModel>[].obs;
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
      case 0:  getDataPrevious();break;
      case 1:  getDataToday();break;
      case 2:  getDataUpComing();break;
      default:getDataToday();
    }
  }

   void addDataTable() {
    listDispatch.value = setDataToday();
  }

  void getDataToday() {
    listDispatch.value = setDataToday();
  }
  void getDataUpComing() {
    listDispatch.value = setDataUpComing();
  }
  void getDataPrevious() {
    listDispatch.value = setDataLast();
  }

  onTapCellNo(String stringId){
      log("id :$stringId");
      try {
        Get.toNamed(AppPages.dispatchDetailPage,arguments:{"title":stringId});
      } catch (e) {
        log("error: $e");
      }
      
  }
  
  List<DispatchModel> setDataToday() {
    return [
      DispatchModel(10001,"2023-07-20",'PT.James Saturna Indonesia',2),
      DispatchModel(10002,"2023-07-20",'PT.Kathryn Indonesia',3),
      DispatchModel(10003,"2023-07-20",'PT.Lara Lancang', 2),
      DispatchModel(10004,"2023-07-20",'PT.Michael Oke',12),
      DispatchModel(10005,"2023-07-20",'PT.Martin Success',4),
      DispatchModel(10006,"2023-07-20",'PT.Newberry Belle',1),
      DispatchModel(10007,"2023-07-20",'PT.Balnc Xianox',7),
      DispatchModel(10008,"2023-07-20",'PT.Perry Supsia',2),
      DispatchModel(10009,"2023-07-20",'PT.Gable Andrusaa', 1),
    ];
  }
  List<DispatchModel> setDataUpComing() {
    return [];
  }
  List<DispatchModel> setDataLast() {
    return [
      DispatchModel(10008,"2023-07-10", 'PT.Daikin Indonesia',  2),
      DispatchModel(10009,"2023-07-17", 'PT.Sehati Karya',  4),
    ];
  }



}





