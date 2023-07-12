
import 'package:get/get.dart';

import '../../../models/product_model.dart';

class InventoryProvider extends GetConnect {
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
      throw ('Error: ${response.statusCode}');
    }
  }

  Future<List<ProductModel>> products(String category) async {
    final response = await get('https://dummyjson.com/products/category/$category');
    if (response.status.hasError) {
      return Future.error(response.status);
    } else {
      final data = response.body["products"];
      final List<ProductModel> itemList = List.from(data.map((item) => ProductModel.fromJson(item)));
      return itemList;
    }
  }
}
