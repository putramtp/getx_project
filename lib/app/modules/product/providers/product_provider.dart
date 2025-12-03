
import 'package:getx_project/app/api_providers.dart';
import 'package:getx_project/app/models/product_detail_model.dart';

class ProductProvider extends ApiProvider {
  // @override
  // void onInit() {
  //   httpClient.baseUrl = '';
  // }

  Future<Map<String, dynamic>> getProductSummaries({String? cursor}) async {
     final response = await get(
      '/stock-transaction/summary/pagination',
      query: cursor != null ? {'cursor': cursor} : {},
    );

    if (response.statusCode == 200 && response.body != null) {
      return response.body;
    } else {
      throw Exception( 'Failed to load getProductSummaries: ${response.statusText}');
    }
  }

  Future<ProductDetailModel> getProductDetail(int productId) async {
     final response = await get('/item/$productId');

    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'];
      if (data is Map<String, dynamic>) {
        return ProductDetailModel.fromJson(data);
      } else {
        throw Exception('Unexpected response format: data is not a Map');
      }
    } else {
      throw Exception( 'Failed to load getProductDetail: ${response.statusText}');
    }
  }

}
