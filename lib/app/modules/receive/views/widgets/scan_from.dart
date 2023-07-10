import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../controllers/receive_controller.dart';

class ScanForm extends StatelessWidget {
  const ScanForm({
    super.key,
    required this.controller,
  });

  final ReceiveController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
    padding: const EdgeInsets.all(20.0),
    child: SingleChildScrollView(
        child: FormBuilder(
      key: controller.formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FormBuilderTextField(
                  name: 'barcode',
                  readOnly: true,
                  decoration: const InputDecoration(
                    icon: Icon(
                      CupertinoIcons.barcode,
                      size: 40,
                    ),
                    // border: InputBorder.none,
                    border:UnderlineInputBorder(),
                  ),
                  controller: controller.barcodeController,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: "Barcode cannot be empty"),
                    FormBuilderValidators.minLength(3),
                  ]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: controller.scanBarcode,
                    child: const Text("SCAN"),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: ElevatedButton(
                      onPressed: controller.resetBarcode,
                      child: const Text("RESET"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    )),
    );
  }
}