import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../styles/app_text_style.dart';
import '../../data/models/serial_number_model.dart';

/// Shared building blocks for the Receive / Outflow order **list** and
/// **detail** screens, so every list row, pagination footer and detail
/// header looks identical across both modules. Colors/icons/text are
/// supplied by each screen; the layout lives here once.

/// A single list row card (receive/outflow order, PO, supplier, customer…).
///
/// [trailingTop] is a small muted line (e.g. item count); [trailingBottom]
/// is the emphasised line (status or date) shown in [trailingBottomColor].
/// [subtitleIcon] and [dateText] are optional extra lines under the title.
Widget orderListCard({
  required double size,
  required IconData leadingIcon,
  required Color accentColor,
  required String title,
  required VoidCallback onTap,
  String? subtitle,
  IconData? subtitleIcon,
  String? dateText,
  String? trailingTop,
  String? trailingBottom,
  Color? trailingBottomColor,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: size * 1.4),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(size * 2),
        onTap: onTap,
        splashColor: accentColor.withOpacity(0.12),
        highlightColor: accentColor.withOpacity(0.06),
        child: Container(
          padding: EdgeInsets.all(size * 1.4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: size * 5,
                height: size * 5,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(size * 1.4),
                ),
                child: Icon(leadingIcon, color: accentColor, size: size * 2.6),
              ),
              SizedBox(width: size * 1.4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.bodyBold(size).copyWith(fontSize: size * 1.6)),
                    if (subtitle != null) ...[
                      SizedBox(height: size * 0.4),
                      Row(
                        children: [
                          if (subtitleIcon != null) ...[
                            Icon(subtitleIcon, size: size * 1.4, color: Colors.grey.shade500),
                            SizedBox(width: size * 0.4),
                          ],
                          Expanded(
                            child: Text(subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle.small(size, color: Colors.grey.shade600)
                                    .copyWith(fontSize: size * 1.3)),
                          ),
                        ],
                      ),
                    ],
                    if (dateText != null) ...[
                      SizedBox(height: size * 0.4),
                      Row(
                        children: [
                          Icon(Icons.date_range_outlined, size: size * 1.4, color: Colors.grey.shade500),
                          SizedBox(width: size * 0.4),
                          Text(dateText,
                              style: AppTextStyle.small(size, color: Colors.grey.shade600)
                                  .copyWith(fontSize: size * 1.2)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingTop != null || trailingBottom != null) ...[
                SizedBox(width: size * 1.2),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (trailingTop != null)
                      Text(trailingTop,
                          style: AppTextStyle.small(size, color: Colors.grey.shade500)),
                    if (trailingTop != null && trailingBottom != null)
                      SizedBox(height: size * 0.5),
                    if (trailingBottom != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: size * 1, vertical: size * 0.4),
                        decoration: BoxDecoration(
                          color: (trailingBottomColor ?? Colors.grey).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(size),
                        ),
                        child: Text(trailingBottom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.small(size,
                                    color: trailingBottomColor ?? Colors.grey.shade700)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Pagination footer for the infinite-scroll lists: a spinner while more
/// pages exist, an end-of-list label once exhausted, otherwise nothing.
Widget orderListFooter(double size,
    {required bool showLoader, required bool showEnd}) {
  if (showLoader) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: size * 2),
      child: const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
  if (showEnd) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: size * 2),
      child: Center(
        child: Text("No more data",
            style: AppTextStyle.small(size, color: Colors.grey.shade500)
                .copyWith(fontSize: size * 1.2, fontWeight: FontWeight.w500)),
      ),
    );
  }
  return const SizedBox.shrink();
}

/// A single row on an "item summary" detail screen (fill / scan flows):
/// a status badge, the item name + progress subtitle, and an optional
/// fill/scan action button shown until the line is complete.
Widget orderItemSummaryTile({
  required double size,
  required String name,
  required String subtitle,
  required IconData statusIcon,
  required Color statusColor,
  required bool showAction,
  required String actionLabel,
  required IconData actionIcon,
  required Color actionColor,
  required VoidCallback onAction,
}) {
  return Container(
    padding: EdgeInsets.all(size * 1.4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(size * 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: size * 5,
          height: size * 5,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(size * 1.4),
          ),
          child: Icon(statusIcon, color: statusColor, size: size * 2.8),
        ),
        SizedBox(width: size * 1.4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.bodyBold(size).copyWith(fontSize: size * 1.5)),
              SizedBox(height: size * 0.5),
              Text(subtitle,
                  style: AppTextStyle.small(size, color: Colors.grey.shade600)
                      .copyWith(fontSize: size * 1.2)),
            ],
          ),
        ),
        if (showAction) ...[
          SizedBox(width: size * 1.2),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(size * 1.2),
              onTap: onAction,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: size * 1.2, vertical: size * 0.9),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(size * 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(actionIcon, size: size * 1.8, color: actionColor),
                    SizedBox(width: size * 0.5),
                    Text(actionLabel,
                        style: AppTextStyle.small(size, color: actionColor)
                            .copyWith(fontWeight: FontWeight.bold, fontSize: size * 1.3)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// A single received/outflowed line in a record-detail screen: item name +
/// quantity, with an optional "view serials" button when serials exist.
Widget orderSerialLineCard({
  required double size,
  required String itemName,
  required num qty,
  required Color accent,
  required List<SerialNumberModel> serials,
  bool showConfirmation = false,
}) {
  final int confirmedCount = serials.where((s) => s.isScanned).length;
  final bool allConfirmed =
      serials.isNotEmpty && confirmedCount == serials.length;
  return Container(
    padding: EdgeInsets.all(size * 1.4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(size * 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: size * 5,
          height: size * 5,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(size * 1.4),
          ),
          child: Icon(Icons.inventory_2_rounded, color: accent, size: size * 2.6),
        ),
        SizedBox(width: size * 1.4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(itemName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.bodyBold(size).copyWith(fontSize: size * 1.5)),
              SizedBox(height: size * 0.4),
              Text("Quantity: $qty",
                  style: AppTextStyle.small(size, color: Colors.grey.shade600)
                      .copyWith(fontSize: size * 1.3)),
              if (showConfirmation && serials.isNotEmpty) ...[
                SizedBox(height: size * 0.4),
                Row(
                  children: [
                    Icon(
                      allConfirmed
                          ? Icons.verified_rounded
                          : Icons.fact_check_outlined,
                      size: size * 1.6,
                      color: allConfirmed ? Colors.green : Colors.orange,
                    ),
                    SizedBox(width: size * 0.4),
                    Text("Confirmed $confirmedCount/${serials.length}",
                        style: AppTextStyle.small(size,
                                color: allConfirmed
                                    ? Colors.green
                                    : Colors.orange)
                            .copyWith(
                                fontSize: size * 1.3,
                                fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (serials.isNotEmpty)
          InkWell(
            borderRadius: BorderRadius.circular(size * 1.2),
            onTap: () => showSerialNumbersDialog(size, itemName, serials, accent,
                showConfirmation: showConfirmation),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: size * 1.2, vertical: size * 0.7),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(size * 1.2),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility_rounded, color: accent, size: size * 1.8),
                  SizedBox(width: size * 0.5),
                  Text("${serials.length}",
                      style: AppTextStyle.small(size, color: accent)
                          .copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

/// Serial-number list dialog shared by the receive & outflow record details.
void showSerialNumbersDialog(
    double size, String itemName, List<SerialNumberModel> serials, Color accent,
    {bool showConfirmation = false}) {
  Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(size * 2)),
      titlePadding: EdgeInsets.fromLTRB(size * 2, size * 2, size * 2, size),
      title: Row(
        children: [
          Icon(Icons.qr_code_2_rounded, color: accent, size: size * 2.4),
          SizedBox(width: size),
          Expanded(
            child: Text("Serial Numbers",
                style: AppTextStyle.h5(size)),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(itemName,
                style: AppTextStyle.small(size, color: Colors.grey.shade600)),
            SizedBox(height: size),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: serials.length,
                separatorBuilder: (_, __) => Divider(height: size * 1.6),
                itemBuilder: (_, i) {
                  final sn = serials[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("${i + 1}.",
                              style: AppTextStyle.bodyBold(size, color: accent)),
                          SizedBox(width: size * 0.6),
                          Expanded(
                            child: Text("SN: ${sn.serialNumber}",
                                style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    fontSize: size * 1.3)),
                          ),
                        ],
                      ),
                      if (sn.internalCode.isNotEmpty)
                        Text("Internal: ${sn.internalCode}",
                            style: AppTextStyle.small(size, color: Colors.grey)),
                      if (sn.expiredDate != null)
                        Text("Expired: ${sn.expiredDate}",
                            style: AppTextStyle.small(size, color: Colors.redAccent)),
                      Text("Active: ${sn.isActive ? "Yes" : "No"}",
                          style: AppTextStyle.small(size,
                              color: sn.isActive ? Colors.green : Colors.red)),
                      if (showConfirmation)
                        Row(
                          children: [
                            Icon(
                              sn.isScanned
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: size * 1.5,
                              color: sn.isScanned ? Colors.green : Colors.orange,
                            ),
                            SizedBox(width: size * 0.4),
                            Expanded(
                              child: Text(
                                sn.isScanned
                                    ? "Confirmed${(sn.scannedByName?.isNotEmpty ?? false) ? " by ${sn.scannedByName}" : ""}"
                                    : "Pending confirmation",
                                style: AppTextStyle.small(size,
                                    color: sn.isScanned
                                        ? Colors.green
                                        : Colors.orange),
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Close")),
      ],
    ),
  );
}

/// Gradient header banner used at the top of detail screens (record detail,
/// item summary). Shows a small [label] above a bold #[code].
Widget orderDetailHeader({
  required double size,
  required String label,
  required String code,
  required IconData icon,
  required List<Color> gradientColors,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(size * 2),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -size * 3,
            right: -size * 3,
            child: Container(
              width: size * 12,
              height: size * 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 2, vertical: size * 1.8),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(size * 1.2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: size * 2.8),
                ),
                SizedBox(width: size * 1.6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTextStyle.body(size, color: Colors.white70)),
                      SizedBox(height: size * 0.3),
                      Text("#$code",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.h3(size, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
