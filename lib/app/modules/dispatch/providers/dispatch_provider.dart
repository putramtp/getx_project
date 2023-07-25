
import 'package:get/get.dart';

import '../../../models/product_model.dart';

class DispatchProvider extends GetConnect {
  // @override
  // void onInit() {
  //   httpClient.baseUrl = '';
  // }

  Future<List<ProductModel>> get10Products() async {
    final response = await get('https://dummyjson.com/products?limit=10');
    if (response.status.hasError) {
      return Future.error(response.status);
    } else {
      final data = response.body["products"];
      final List<ProductModel> itemList = List.from(data.map((item) => ProductModel.fromJson(item)));
      return itemList;
    }
  }



}
