import 'dart:typed_data';

import 'package:get/get.dart';

import 'api_providers.dart';
import '../models/delivery_model.dart';
import '../models/delivery_status_model.dart';

class DeliveryProvider extends ApiProvider {
  /// `GET /delivery` — returns every delivery at once (no pagination on the
  /// backend), so the controller filters/sorts client-side.
  Future<List<DeliveryModel>> getDeliveries() {
    return getList('/delivery', DeliveryModel.fromJson);
  }

  Future<DeliveryModel> getDeliveryDetail(int id) async {
    final response = await get('/delivery/$id');
    checkResponse(response);
    return DeliveryModel.fromJson(response.body['data'] as Map<String, dynamic>);
  }

  /// `GET /delivery-status` — the status options (Pending / Shipped /
  /// Delivered / Cancelled) with their backend-defined colors.
  Future<List<DeliveryStatusModel>> getDeliveryStatuses() {
    return getList('/delivery-status', DeliveryStatusModel.fromJson);
  }

  /// `PUT /delivery/{id}` — status_id / estimate_at / address are required by
  /// the backend (it stamps `updated_by` from the token); estimate_time /
  /// description are optional, receiver_name is required on the move to Delivered.
  Future<DeliveryModel> updateDelivery(int id, Map<String, dynamic> payload) async {
    final response = await put('/delivery/$id', payload);
    checkResponse(response);
    return DeliveryModel.fromJson(response.body['data'] as Map<String, dynamic>);
  }

  /// `POST /delivery/{id}/undo-status` — steps a wrong status back one step
  /// (needs the `delivery.undo-status` permission). Returns the delivery.
  Future<DeliveryModel> undoStatus(int id, String reason) async {
    final response = await post('/delivery/$id/undo-status', {'reason': reason});
    checkResponse(response);
    return DeliveryModel.fromJson(response.body['data'] as Map<String, dynamic>);
  }

  /// `POST /delivery/{id}/proofs` — attaches a photo or the signed delivery
  /// note (jpg/png/webp/pdf, ≤ 20 MB) to a Delivered delivery.
  Future<Map<String, dynamic>> uploadProof(int id, List<int> bytes, String filename) {
    return postMap('/delivery/$id/proofs', FormData({'file': MultipartFile(bytes, filename: filename)}));
  }

  /// `GET /delivery/{id}/proofs/{media}/preview` — the proof file's bytes.
  Future<Uint8List> getProofBytes(int id, int mediaId) {
    return getBytes('/delivery/$id/proofs/$mediaId/preview');
  }

  /// `POST /outflow-order/createDelivery` — creates the delivery linked to an
  /// outflow order (status defaults to Pending on the backend). Returns the
  /// updated outflow order; the delivery itself is read back from the list.
  Future<Map<String, dynamic>> createDelivery(int outflowOrderId) {
    return postMap('/outflow-order/createDelivery', {'id': outflowOrderId});
  }
}
