import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../../data/models/delivery_status_model.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/variables.dart';
import '../../../global/widget/app_buttons.dart';

/// The status's backend hex color; navy when it is missing.
Color deliveryStatusColor(DeliveryStatusModel s) => s.color.trim().isEmpty ? navyMid : HexColor(s.color);

/// "Update status" card on Delivery Detail: a "Now: `<status>`" hint, one
/// outline "Mark `<status>`" button per other status (API color, navy when
/// unreadable on white) and "Edit details".
Widget deliveryStatusPanel(
  double size, {
  required DeliveryStatusModel current,
  required List<DeliveryStatusModel> others,
  required void Function(DeliveryStatusModel) onMark,
  required VoidCallback onEdit,
}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(size * 1.6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(size * 1.7),
      border: Border.all(color: steelBlue.withValues(alpha: 0.18)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text("Update status", style: AppTextStyle.h5(size, weight: FontWeight.w700))),
            Flexible(
              child: Text(
                "Now: ${current.name}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.small(size, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
        SizedBox(height: size * 1.2),
        Wrap(
          spacing: size * 1.0,
          runSpacing: size * 1.0,
          children: [
            for (final s in others)
              accentOutlineButton(
                size,
                "Mark ${s.name}",
                color: deliveryStatusColor(s),
                icon: Icons.check_circle_outline_rounded,
                onPressed: () => onMark(s),
              ),
          ],
        ),
        SizedBox(height: size * 1.2),
        SizedBox(
          width: double.infinity,
          child: accentOutlineButton(
            size,
            "Edit details",
            color: navyDark,
            icon: Icons.edit_outlined,
            onPressed: onEdit,
          ),
        ),
      ],
    ),
  );
}
