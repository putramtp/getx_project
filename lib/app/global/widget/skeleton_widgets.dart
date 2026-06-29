import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'order_list_widgets.dart';

/// Shared Skeletonizer loading placeholders. The app shows these (shimmering
/// fake rows that mirror the real layout) instead of a "Loading..." label
/// while data is in flight. Wrap real content in [skeletonize] for refreshes,
/// or return one of the list placeholders for first loads.

/// Wrap any real widget so it shimmers while [loading] is true.
Widget skeletonize({required bool loading, required Widget child}) {
  return Skeletonizer(enabled: loading, child: child);
}

/// First-load placeholder for the order family lists (receive / outflow /
/// delivery) — fake [orderListCard]s so the shimmer matches the real cards.
Widget skeletonOrderList(double size, {Color accent = Colors.grey, int count = 7}) {
  return Skeletonizer(
    enabled: true,
    child: ListView.builder(
      itemCount: count,
      shrinkWrap: true,
      itemBuilder: (_, __) => orderListCard(
        size: size,
        leadingIcon: Icons.inventory_2_rounded,
        accentColor: accent,
        title: 'Loading code 0000',
        subtitle: 'Loading name placeholder',
        subtitleIcon: Icons.person_outline_rounded,
        dateText: '0000-00-00',
        trailingBottom: 'STATUS',
        trailingBottomColor: accent,
        onTap: () {},
      ),
    ),
  );
}

/// First-load placeholder for record-detail line lists (item name + qty cards).
Widget skeletonLineList(double size, {Color accent = Colors.grey, int count = 5}) {
  return Skeletonizer(
    enabled: true,
    child: ListView.separated(
      itemCount: count,
      shrinkWrap: true,
      separatorBuilder: (_, __) => SizedBox(height: size * 1.2),
      itemBuilder: (_, __) => orderSerialLineCard(
        size: size,
        itemName: 'Loading item name placeholder',
        qty: 0,
        accent: accent,
        serials: const [],
      ),
    ),
  );
}

/// First-load placeholder for the item-summary tiles (fill / scan flows).
Widget skeletonSummaryList(double size, {Color accent = Colors.grey, int count = 5}) {
  return Skeletonizer(
    enabled: true,
    child: ListView.separated(
      itemCount: count,
      shrinkWrap: true,
      separatorBuilder: (_, __) => SizedBox(height: size * 1.2),
      itemBuilder: (_, __) => orderItemSummaryTile(
        size: size,
        name: 'Loading item name',
        subtitle: 'Loading progress 0 / 0',
        statusIcon: Icons.inventory_2_rounded,
        statusColor: accent,
        showAction: false,
        actionLabel: '',
        actionIcon: Icons.qr_code_scanner_rounded,
        actionColor: accent,
        onAction: () {},
      ),
    ),
  );
}

/// Generic card-row placeholder for lists that don't use the order widgets
/// (products, transactions, categories, brands, units).
Widget skeletonGenericList(double size, {int count = 8}) {
  return Skeletonizer(
    enabled: true,
    child: ListView.builder(
      itemCount: count,
      shrinkWrap: true,
      itemBuilder: (_, __) => Padding(
        padding: EdgeInsets.only(bottom: size * 1.4),
        child: Container(
          padding: EdgeInsets.all(size * 1.4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 2),
          ),
          child: Row(
            children: [
              Container(
                width: size * 5,
                height: size * 5,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(size * 1.4),
                ),
              ),
              SizedBox(width: size * 1.4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Loading placeholder title here'),
                    SizedBox(height: 6),
                    Text('Loading secondary line'),
                  ],
                ),
              ),
              const Text('0000'),
            ],
          ),
        ),
      ),
    ),
  );
}
