import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../accent.dart';
import '../styles/app_text_style.dart';
import '../variables.dart';
import 'accent_header_card.dart';
import 'accent_pill.dart';
import 'app_buttons.dart';
import 'functions_widget.dart';
import '../../data/models/serial_number_model.dart';
import '../functions.dart';

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
        splashColor: accentColor.withValues(alpha: 0.12),
        highlightColor: accentColor.withValues(alpha: 0.06),
        child: Container(
          padding: EdgeInsets.all(size * 1.4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                  color: accentColor.withValues(alpha: 0.12),
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
                          color: (trailingBottomColor ?? Colors.grey).withValues(alpha: 0.12),
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
    return NoMoreDataFooter(size: size);
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
  String? blockedReason,
}) {
  final blocked = blockedReason != null;
  return Container(
    padding: EdgeInsets.all(size * 1.4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(size * 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
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
            color: statusColor.withValues(alpha: 0.12),
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
              if (blocked) ...[
                SizedBox(height: size * 0.6),
                Row(
                  key: const Key('orderLineBlockedReason'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: size * 1.5, color: amberDark),
                    SizedBox(width: size * 0.5),
                    Expanded(
                      child: Text(blockedReason,
                          style: AppTextStyle.small(size, color: amberDark)
                              .copyWith(fontSize: size * 1.2, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (showAction && !blocked) ...[
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
                  color: actionColor.withValues(alpha: 0.12),
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
          color: Colors.black.withValues(alpha: 0.05),
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
            color: accent.withValues(alpha: 0.12),
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
              Text("Quantity: ${formatQty(qty)}",
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
                color: accent.withValues(alpha: 0.1),
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
                separatorBuilder: (_, _) => Divider(height: size * 1.6),
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
        TextButton(onPressed: () => closeRoute(), child: const Text("Close")),
      ],
    ),
  );
}

/// Totals over the Item Summary lines: [expected] target (expected qty for
/// receive, reserved qty for outflow), [done] already received/outflowed,
/// [pending] filled/scanned in this session, and how many lines are complete.
class LineTotals {
  const LineTotals(this.expected, this.done, this.pending, this.lines, this.linesDone);
  final num expected;
  final num done;
  final num pending;
  final int lines;
  final int linesDone;
}

LineTotals lineTotals(List<Map<String, dynamic>> items, {required String expectedKey, required String pendingKey}) {
  num expected = 0, done = 0, pending = 0;
  var linesDone = 0;
  for (final item in items) {
    final e = safeToNum(item[expectedKey]);
    final d = safeToNum(item['received']);
    final p = sumQty(List<Map>.from(item[pendingKey] ?? const []));
    expected += e;
    done += d;
    pending += p;
    if (e > 0 && roundQty(d + p) >= e) linesDone++;
  }
  return LineTotals(roundQty(expected), roundQty(done), roundQty(pending), items.length, linesDone);
}

/// Item Summary header (receive By-PO/Supplier, outflow By-Request/Customer):
/// [accentHeaderCard] with target / done / in-progress stats and a two-tone
/// progress bar. [labels] = (target, done, pending) stat labels, e.g.
/// ('Expected', 'Received', 'Receiving now'); [doneVerb] ends the caption.
Widget orderSummaryHeader({
  required double size,
  required AppAccent accent,
  required IconData icon,
  required String label,
  required String title,
  required LineTotals totals,
  required (String, String, String) labels,
  required String doneVerb,
  String? code,
  Widget? badge,
  String? footer,
  IconData footerIcon = Icons.info_outline_rounded,
}) {
  final target = totals.expected;
  return accentHeaderCard(
    size: size,
    accent: accent,
    icon: icon,
    label: label,
    title: title,
    code: code,
    badge: badge,
    stats: [
      HeaderStat(labels.$1, formatQty(target)),
      HeaderStat(labels.$2, formatQty(totals.done), color: navyMid),
      HeaderStat(labels.$3, formatQty(totals.pending), color: accent.text),
    ],
    footer: footer,
    footerIcon: footerIcon,
    progress: AccentProgress(
      [
        ProgressSegment(target > 0 ? totals.done / target : 0, navyMid, legend: labels.$2),
        ProgressSegment(target > 0 ? totals.pending / target : 0, accent.base, legend: 'Now'),
      ],
      caption: '${totals.linesDone} of ${totals.lines} lines $doneVerb',
      showLegend: true,
    ),
  );
}

/// Receive Order / Outflow Order detail header: record code, `type` badge,
/// Lines / Total qty (+ in, - out) / Date stats and an optional [progress].
Widget orderRecordHeader({
  required double size,
  required AppAccent accent,
  required IconData icon,
  required String label,
  required String code,
  required AppAccent typeAccent,
  required bool isIn,
  String? type,
  int lines = 0,
  num totalQty = 0,
  DateTime? date,
  String? footer,
  IconData footerIcon = Icons.info_outline_rounded,
  AccentProgress? progress,
}) {
  return accentHeaderCard(
    size: size,
    accent: accent,
    icon: icon,
    label: label,
    title: '#$code',
    badge: type == null || type.isEmpty ? null : accentPill(size, type, accent: typeAccent),
    stats: [
      HeaderStat('Lines', '$lines'),
      HeaderStat(
        'Total qty',
        '${isIn ? '+' : '-'}${formatQty(totalQty)}',
        color: isIn ? stockInColor : stockOutColor,
      ),
      HeaderStat('Date', date == null ? '-' : getDateString(date)),
    ],
    footer: footer,
    footerIcon: footerIcon,
    progress: progress,
  );
}

/// One line of [orderSubmitConfirmDialog]: an item and the entries about to be
/// submitted for it ("Filled: 2", a scanned label, ...).
class SubmitConfirmLine {
  const SubmitConfirmLine({required this.name, required this.entries, this.total});

  final String name;
  final List<String> entries;

  /// Shown as "Total: n" next to the name when set.
  final num? total;
}

/// Confirmation before submitting a receive / outflow (By PO, By Supplier,
/// By Request, By Customer). Pass only the lines that have something filled or
/// scanned — the ones being submitted. The list scrolls when it is long while
/// Cancel / Continue stay pinned under it, so Continue is never pushed off
/// screen. Pops `true` on Continue, `false` on Cancel.
Widget orderSubmitConfirmDialog({
  required double size,
  required AppAccent accent,
  required Widget title,
  required String summary,
  required List<SubmitConfirmLine> lines,
  IconData entryIcon = Icons.list_rounded,
}) {
  return Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: accent.tint(), shape: BoxShape.circle),
              child: Icon(Icons.receipt_long_rounded, color: accent.base, size: 40),
            ),
          ),
          const SizedBox(height: 18),
          title,
          const SizedBox(height: 12),
          Text(
            summary,
            style: AppTextStyle.custom(size, px: 16, weight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [for (final line in lines) _submitConfirmLineCard(size, line, entryIcon)],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: accentOutlineButton(size, 'Cancel',
                    color: accent.base, onPressed: () => closeRoute(false)),
              ),
              const SizedBox(width: 12),
              Expanded(child: navyButton(size, 'Continue', onPressed: () => closeRoute(true))),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _submitConfirmLineCard(double size, SubmitConfirmLine line, IconData entryIcon) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2_rounded, size: 20, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(line.name,
                  style: AppTextStyle.custom(size, px: 15, weight: FontWeight.w600, color: Colors.black87)),
            ),
            if (line.total != null)
              Text('Total: ${formatQty(line.total!)}',
                  style: AppTextStyle.plain(weight: FontWeight.w500, color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 6),
        for (final entry in line.entries)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
            child: Row(
              children: [
                Icon(entryIcon, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(entry, style: AppTextStyle.custom(size, px: 13, color: Colors.black54)),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Outflow entry as listed in [orderSubmitConfirmDialog]: the scanned label
/// (with its qty when more than 1), or just the qty for a quantity-only line.
String scannedEntryLabel(Map<String, dynamic> entry) {
  final code = entry['serial_number'];
  final qty = safeToNum(entry['qty']);
  if (code == null) return 'scanned: ${formatQty(qty)}';
  return qty == 1 ? '$code' : '$code (qty: ${formatQty(qty)})';
}
