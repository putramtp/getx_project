import 'api_providers.dart';
import '../models/product_detail_model.dart';

class ProductProvider extends ApiProvider {
  Future<Map<String, dynamic>> getProductSummaries({String? cursor, Map<String, String>? params}) async {
    final response = await get(
      '/stock-transaction/summary/pagination',
      query: {
        if (params != null) ...params,
        if (cursor != null) 'cursor': cursor,
      },
    );
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }

  Future<Map<String, dynamic>> getProductSummariesByCategory({required int catId, String? cursor}) async {
    final response = await get(
      '/stock-transaction/summary/item-category/${catId.toString()}/pagination',
      query: cursor != null ? {'cursor': cursor} : {},
    );
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }

  Future<Map<String, dynamic>> getProductSummariesByBrand({required int brandId, String? cursor}) async {
    final response = await get(
      '/stock-transaction/summary/item-brand/${brandId.toString()}/pagination',
      query: cursor != null ? {'cursor': cursor} : {},
    );
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }

  Future<ProductDetailModel> getProductDetail(int productId) async {
    final response = await get('/item/$productId');
    checkResponse(response);
    return ProductDetailModel.fromJson(response.body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getStockTransactionByProduct({required int productId, String? cursor}) async {
    final response = await get(
      '/stock-transaction/product/${productId.toString()}',
      query: cursor != null ? {'cursor': cursor} : {},
    );
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }

  Future<Map<String, dynamic>> getProductCategories({String? cursor, Map<String, String>? params}) async {
    final response = await get(
      '/item-category/pagination',
      query: {
        if (params != null) ...params,
        if (cursor != null) 'cursor': cursor,
      },
    );
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }

  Future<Map<String, dynamic>> getProductUnits({String? cursor, Map<String, String>? params}) async {
    final response = await get(
      '/unit/pagination',
      query: {
        if (params != null) ...params,
        if (cursor != null) 'cursor': cursor,
      },
    );
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }

  Future<Map<String, dynamic>> getProductBrands({String? cursor, Map<String, String>? params}) async {
    final response = await get(
      '/item-brand/pagination',
      query: {
        if (params != null) ...params,
        if (cursor != null) 'cursor': cursor,
      },
    );
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }
}
