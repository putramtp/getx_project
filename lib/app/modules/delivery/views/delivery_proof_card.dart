import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/delivery_model.dart';
import '../../../global/functions.dart';
import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/variables.dart';
import '../../../global/widget/app_buttons.dart';

/// "Proof of delivery" card on a Delivered delivery: the attached photos /
/// signed notes — tap one to open it ([onOpen]) — plus "Take photo" and "From
/// gallery" to add one. While an upload runs ([uploading]) the buttons give way
/// to a spinner.
Widget deliveryProofCard(
  double size, {
  required List<DeliveryProof> proofs,
  required bool uploading,
  required VoidCallback onCamera,
  required VoidCallback onGallery,
  required void Function(DeliveryProof) onOpen,
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
        Text("Proof of delivery", style: AppTextStyle.h5(size, weight: FontWeight.w700)),
        SizedBox(height: size * 0.8),
        if (proofs.isEmpty)
          Text("No photo or signed delivery note yet.",
              style: AppTextStyle.small(size, color: Colors.grey.shade700))
        else
          for (final p in proofs)
            InkWell(
              key: Key('deliveryProof${p.id}'),
              borderRadius: BorderRadius.circular(size * 0.8),
              onTap: () => onOpen(p),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: size * 0.6),
                child: Row(
                  children: [
                    Icon(p.isImage ? Icons.image_outlined : Icons.attach_file_rounded,
                        size: size * 1.8, color: Colors.grey.shade600),
                    SizedBox(width: size * 0.8),
                    Expanded(
                      child: Text(p.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyle.body(size)),
                    ),
                    if (p.size.isNotEmpty)
                      Text(p.size, style: AppTextStyle.small(size, color: Colors.grey.shade600)),
                    SizedBox(width: size * 0.4),
                    Icon(Icons.chevron_right_rounded, size: size * 1.8, color: Colors.grey.shade500),
                  ],
                ),
              ),
            ),
        SizedBox(height: size * 1.2),
        if (uploading)
          const Center(child: CircularProgressIndicator())
        else
          Row(
            children: [
              Expanded(
                child: accentOutlineButton(size, "Take photo",
                    color: navyDark, icon: Icons.photo_camera_outlined, onPressed: onCamera),
              ),
              SizedBox(width: size),
              Expanded(
                child: accentOutlineButton(size, "From gallery",
                    color: navyDark, icon: Icons.photo_library_outlined, onPressed: onGallery),
              ),
            ],
          ),
      ],
    ),
  );
}

/// Full-screen preview of a proof photo, pinch to zoom; Close pops it.
Future<void> showProofPreview(String title, Uint8List bytes) {
  final size = SizeConfig.defaultSize;
  return Get.dialog<void>(
    Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: size * 1.6),
                    child: Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.body(size, color: Colors.white)),
                  ),
                ),
                IconButton(
                  key: const Key('deliveryProofClose'),
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => closeRoute(),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
