import 'api_providers.dart';
import '../models/product_detail_model.dart';

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
    final resBody =  response.body;
    if (response.statusCode == 200 &&resBody != null && resBody['success'] == true) {
      return resBody;
    } else {
      throw Exception( 'Failed to load getProductSummaries: ${response.statusText}');
    }
  }

  Future<Map<String, dynamic>> getProductSummariesByCategory({required int catId,String? cursor}) async {
     final response = await get(
      '/stock-transaction/summary/item-category/${catId.toString()}/pagination',
      query: cursor != null ? {'cursor': cursor} : {},
    );
    final resBody =  response.body;
    if (response.statusCode == 200 &&resBody != null && resBody['success'] == true) {
      return resBody;
    } else {
      throw Exception( 'Failed to load getProductSummariesByCategory: ${response.statusText}');
    }
  }

  Future<Map<String, dynamic>> getProductSummariesByBrand({required int brandId,String? cursor}) async {
     final response = await get(
      '/stock-transaction/summary/item-brand/${brandId.toString()}/pagination',
      query: cursor != null ? {'cursor': cursor} : {},
    );
    final resBody =  response.body;
    if (response.statusCode == 200 &&resBody != null && resBody['success'] == true) {
      return resBody;
    } else {
      throw Exception( 'Failed to load getProductSummariesByBrand: ${response.statusText}');
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

 Future<Map<String, dynamic>> getStockTransactionByProduct({required int productId,String? cursor}) async {
     final response = await get(
      '/stock-transaction/product/${productId.toString()}',
      query: cursor != null ? {'cursor': cursor} : {},
    );

    if (response.statusCode == 200 && response.body != null) {
      return response.body;
    } else {
      throw Exception( 'Failed to load getStockTransactionByProduct: ${response.statusText}');
    }
  }

  Future<Map<String, dynamic>> getProductCategories({String? cursor}) async {
     final response = await get(
      '/item-category/pagination',
      query: cursor != null ? {'cursor': cursor} : {},
    );
    final resBody =  response.body;
    if (response.statusCode == 200 &&resBody != null && resBody['success'] == true) {
      return resBody;
    } else {
      throw Exception( 'Failed to load getProductCategories: ${response.statusText}');
    }
  }

  Future<Map<String, dynamic>> getProductBrands({String? cursor}) async {
     final response = await get(
      '/item-brand/pagination',
      query: cursor != null ? {'cursor': cursor} : {},
    );
    final resBody =  response.body;
    if (response.statusCode == 200 &&resBody != null && resBody['success'] == true) {
      return resBody;
    } else {
      throw Exception( 'Failed to load getProductBrands: ${response.statusText}');
    }
  }
 

}
