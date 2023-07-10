
import 'package:get/get.dart';

class ReceivingOrderProvider extends GetConnect {
  // @override
  // void onInit() {
  //   httpClient.baseUrl = 'https://dummyjson.com/products/categories';
  // }

  Future<List<String>> categories() async {
    final response = await get('https://dummyjson.com/products/categories');
      if (response.statusCode == 200) {
      List<String> stringList = List<String>.from(response.body);
      return stringList;
    } else {
      throw('Error: ${response.statusCode}');
    }
  }


}
