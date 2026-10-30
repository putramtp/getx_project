/// A delivery record, as returned by `GET /delivery`, `GET /delivery/{id}` and
/// `PUT /delivery/{id}` (all share the same `DeliveryResource` shape on the
/// backend). A delivery is header-only — it carries logistics/status data and
/// links back to one outflow order; the actual line items live on that order.
class DeliveryModel {
  final int id;
  final String code;
  final String customer;
  final int? outflowOrderId;
  final String? outflowOrderCode;
  final int statusId;

  /// The stored status name ("Pending") — compare against this in logic.
  final String statusName;

  /// What a person reads (`status_label`, e.g. "Scheduled"). Display only.
  final String statusLabel;
  final int? updatedBy;
  final String updatedName;

  /// Estimated delivery date, `yyyy-MM-dd` (null until first set).
  final String? estimateAt;

  /// Estimated delivery time, `HH:mm` (null until first set).
  final String? estimateTime;
  final String address;
  final String? description;

  /// Who received the goods — set on the move to Delivered, null before.
  final String? receiverName;

  /// When the goods arrived (local time, `yyyy-MM-dd HH:mm`), null until Delivered.
  final String? deliveredAt;

  /// Status ids this delivery may move to next (`next_statuses`). Only the
  /// detail/update responses carry it; null on list rows. Empty = final status.
  final List<int>? nextStatusIds;

  /// Photos / signed delivery notes attached once Delivered (detail only).
  final List<DeliveryProof> proofs;

  /// Whether the current user may step the status back one step (`undo.available`),
  /// the status it would go back to, and why not when unavailable.
  final bool undoAvailable;
  final String? undoToName;
  final String? undoToLabel;
  final String? undoRefusal;

  DeliveryModel({
    required this.id,
    required this.code,
    required this.customer,
    this.outflowOrderId,
    this.outflowOrderCode,
    required this.statusId,
    required this.statusName,
    String? statusLabel,
    this.updatedBy,
    required this.updatedName,
    this.estimateAt,
    this.estimateTime,
    required this.address,
    this.description,
    this.receiverName,
    this.deliveredAt,
    this.nextStatusIds,
    this.proofs = const [],
    this.undoAvailable = false,
    this.undoToName,
    this.undoToLabel,
    this.undoRefusal,
  }) : statusLabel = statusLabel ?? statusName;

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    final undo = json['undo'] is Map ? json['undo'] as Map : const {};
    final undoTo = undo['to'] is Map ? undo['to'] as Map : const {};
    return DeliveryModel(
      id: json['id'],
      code: json['code']?.toString() ?? '-',
      customer: json['customer']?.toString() ?? 'N/A',
      outflowOrderId: json['outflow_order_id'],
      outflowOrderCode: json['outflow_order_code']?.toString(),
      statusId: (num.tryParse(json['status_id']?.toString() ?? '') ?? 0).toInt(),
      statusName: json['status_name']?.toString() ?? '-',
      statusLabel: json['status_label']?.toString(),
      updatedBy: json['updated_by'],
      updatedName: json['updated_name']?.toString() ?? 'N/A',
      estimateAt: json['estimate_at']?.toString(),
      estimateTime: json['estimate_time']?.toString(),
      address: json['address']?.toString() ?? '',
      description: json['description']?.toString(),
      receiverName: json['receiver_name']?.toString(),
      deliveredAt: _localDateTime(json['delivered_at']),
      nextStatusIds: json['next_statuses'] is List
          ? (json['next_statuses'] as List)
              .whereType<Map>()
              .map((s) => (num.tryParse(s['id']?.toString() ?? '') ?? 0).toInt())
              .toList()
          : null,
      proofs: json['proofs'] is List
          ? (json['proofs'] as List).whereType<Map>().map((p) => DeliveryProof.fromJson(p)).toList()
          : const [],
      undoAvailable: undo['available'] == true,
      undoToName: undoTo['name']?.toString(),
      undoToLabel: (undoTo['label'] ?? undoTo['name'])?.toString(),
      undoRefusal: undo['reason']?.toString(),
    );
  }

  /// The backend sends `delivered_at` as a UTC instant; show it in device time.
  static String? _localDateTime(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return null;
    final t = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}

/// One proof-of-delivery file (`proofs[]` on the delivery detail).
class DeliveryProof {
  final int id;
  final String title;
  final String size;
  final String mimeType;

  const DeliveryProof({required this.id, required this.title, required this.size, this.mimeType = ''});

  /// A photo the app previews itself; other files (a PDF note) are opened elsewhere.
  bool get isImage => mimeType.startsWith('image/');

  factory DeliveryProof.fromJson(Map json) => DeliveryProof(
        id: (num.tryParse(json['id']?.toString() ?? '') ?? 0).toInt(),
        title: json['title']?.toString() ?? json['file_name']?.toString() ?? 'File',
        size: json['size']?.toString() ?? '',
        mimeType: json['mime_type']?.toString() ?? '',
      );
}
