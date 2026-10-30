import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/models/delivery_model.dart';
import 'package:getx_project/app/modules/delivery/views/delivery_proof_card.dart';

import 'pump_ui.dart';

void main() {
  testWidgets('tapping a proof opens it', (tester) async {
    const photo = DeliveryProof(id: 11, title: 'foto.jpg', size: '312 KB', mimeType: 'image/jpeg');
    DeliveryProof? opened;
    await pumpUi(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: deliveryProofCard(
            9.6,
            proofs: const [photo],
            uploading: false,
            onCamera: () {},
            onGallery: () {},
            onOpen: (p) => opened = p,
          ),
        ),
      ),
    );

    await tester.tap(find.text('foto.jpg'));
    expect(opened?.id, 11);
  });
}
