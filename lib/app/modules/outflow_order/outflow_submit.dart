import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/providers/api_providers.dart';
import '../../global/functions.dart';
import '../../global/size_config.dart';
import '../../global/styles/app_text_style.dart';
import '../../global/variables.dart';
import '../../helpers/api_excecutor.dart';

/// Shared outflow submit for By Request, By Customer (`outflowData`) and By
/// Work Order (`issue-by-work-order`) — [send] posts the payload.
///
/// When the backend answers `409 expired_batch` (the scan would take expired
/// batches or serials out of stock), lists them and resends with
/// `confirm_expired: true` once the user confirms. Returns the response, or
/// null when it failed (error already shown) or the user backed out.
Future<Map<String, dynamic>?> submitOutflowData(
  Future<Map<String, dynamic>> Function(Map<String, dynamic>) send,
  Map<String, dynamic> payload, {
  required RxBool isLoading,
}) async {
  ExpiredStockException? expired;
  final data = await ApiExecutor.run<Map<String, dynamic>?>(
    isLoading: isLoading,
    task: () async {
      try {
        return await send(payload);
      } on ExpiredStockException catch (e) {
        expired = e;
        return null;
      }
    },
  );
  final warning = expired;
  if (data != null || warning == null) return data;
  if (!await _confirmExpired(warning)) return null;

  return ApiExecutor.run(
    isLoading: isLoading,
    task: () => send({...payload, 'confirm_expired': true}),
  );
}

/// `POST /outflow-order/issue-by-work-order` body from the Item Summary lines:
/// only lines with something filled/scanned, each with its total qty and its
/// scanned serials (`{serial_number, qty}`) as `selected_serials`.
Map<String, dynamic> workOrderIssuePayload(int workOrderId, Iterable<Map<String, dynamic>> items) => {
      'work_order_id': workOrderId,
      'outflow_order_lines': [
        for (final line in linesToSubmit(items, 'scanned'))
          {
            'or_line_id': line['line_id'],
            'item_id': line['item_id'],
            'qty': sumQty(List<Map>.from(line['scanned'] as List)),
            'selected_serials': [
              for (final e in line['scanned'] as List)
                if (e['serial_number'] != null) e,
            ],
          },
      ],
    };

Future<bool> _confirmExpired(ExpiredStockException e) async {
  final size = SizeConfig.defaultSize;
  final result = await Get.dialog<bool>(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: amberDark),
          const SizedBox(width: 10),
          Expanded(child: Text("Expired stock", style: AppTextStyle.h5(size))),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: size * 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("These batches or serials have expired:", style: AppTextStyle.body(size)),
              SizedBox(height: size),
              for (final line in e.expired.isEmpty ? [e.message] : e.expired)
                Padding(
                  padding: EdgeInsets.only(bottom: size * 0.6),
                  child: Text("• $line", style: AppTextStyle.small(size, color: amberDark)),
                ),
              SizedBox(height: size * 0.6),
              Text("Issue them anyway?", style: AppTextStyle.bodyBold(size)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => closeRoute(false),
          child: Text("Cancel", style: AppTextStyle.plain(color: Colors.grey)),
        ),
        ElevatedButton(
          key: const Key('outflowConfirmExpiredButton'),
          onPressed: () => closeRoute(true),
          style: ElevatedButton.styleFrom(backgroundColor: navyDark, foregroundColor: Colors.white),
          child: const Text("Issue anyway"),
        ),
      ],
    ),
  );
  return result ?? false;
}
