import 'api_providers.dart';
import '../models/delivery_model.dart';
import '../models/delivery_status_model.dart';

class DeliveryProvider extends ApiProvider {
  /// `GET /delivery` — returns every delivery at once (no pagination on the
  /// backend), so the controller filters/sorts client-side.
  Future<List<DeliveryModel>> getDeliveries() async {
    final response = await get('/delivery');
    checkResponse(response);
    final List data = response.body['data'] ?? [];
    return data.map((e) => DeliveryModel.fromJson(e)).toList();
  }

  Future<DeliveryModel> getDeliveryDetail(int id) async {
    final response = await get('/delivery/$id');
    checkResponse(response);
    return DeliveryModel.fromJson(response.body['data'] as Map<String, dynamic>);
  }

  /// `GET /delivery-status` — the status options (Pending / Shipped /
  /// Delivered / Cancelled) with their backend-defined colors.
  Future<List<DeliveryStatusModel>> getDeliveryStatuses() async {
    final response = await get('/delivery-status');
    checkResponse(response);
    final List data = response.body['data'] ?? [];
    return data.map((e) => DeliveryStatusModel.fromJson(e)).toList();
  }

  /// `PUT /delivery/{id}` — status_id / updated_by / estimate_at / address are
  /// required by the backend; estimate_time / description are optional.
  Future<DeliveryModel> updateDelivery(int id, Map<String, dynamic> payload) async {
    final response = await put('/delivery/$id', payload);
    checkResponse(response);
    return DeliveryModel.fromJson(response.body['data'] as Map<String, dynamic>);
  }

  /// `POST /outflow-order/createDelivery` — creates the delivery linked to an
  /// outflow order (status defaults to Pending on the backend). Returns the
  /// updated outflow order; the delivery itself is read back from the list.
  Future<Map<String, dynamic>> createDelivery(int outflowOrderId) async {
    final response = await post('/outflow-order/createDelivery', {'id': outflowOrderId});
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }

  /// `GET /user/currentDetail` — resolves the authenticated user's id, used as
  /// `updated_by` when updating a delivery (the /login response omits the id).
  Future<int?> getCurrentUserId() async {
    final response = await get('/user/currentDetail');
    checkResponse(response);
    final data = response.body['data'];
    final id = (data is Map) ? data['id'] : null;
    return (id is int) ? id : int.tryParse(id?.toString() ?? '');
  }
}
