import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/workspace_sign_in_model.dart';
import '../../../global/functions.dart';
import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/variables.dart';

/// The email sign-in's `choose` answer: the email and password open several
/// companies. Resolves with the picked one, or null when dismissed. Tiles are
/// keyed `loginCompanyChoice_<index>` for tests.
Future<WorkspaceTenant?> showCompanyChooser(List<WorkspaceTenant> tenants) {
  final size = SizeConfig.defaultSize;
  return Get.bottomSheet<WorkspaceTenant>(
    Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      // SafeArea: keep the last company above Android's 3-button navigation bar.
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: Get.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: size * 1.2),
                  width: size * 4,
                  height: size * 0.4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(size)),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(size * 2, size * 2, size * 2, size * 0.6),
                child: Text('Choose a company', style: AppTextStyle.h4(size, color: navyDark)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size * 2),
                child: Text(
                  'This email belongs to more than one company. Pick the one to open.',
                  style: AppTextStyle.body(size, color: Colors.grey.shade700),
                ),
              ),
              SizedBox(height: size),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(size * 2, size * 0.6, size * 2, size * 2),
                  itemCount: tenants.length,
                  separatorBuilder: (_, _) => SizedBox(height: size),
                  itemBuilder: (_, i) => _companyTile(size, i, tenants[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

Widget _companyTile(double size, int index, WorkspaceTenant tenant) {
  final radius = BorderRadius.circular(size * 1.4);
  return Material(
    color: pageBackground,
    borderRadius: radius,
    child: InkWell(
      key: Key('loginCompanyChoice_$index'),
      borderRadius: radius,
      onTap: () => closeRoute(tenant),
      child: Padding(
        padding: EdgeInsets.all(size * 1.4),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(size * 0.9),
              decoration: BoxDecoration(color: navyMid.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(size)),
              child: Icon(Icons.apartment_rounded, color: navyMid, size: size * 2),
            ),
            SizedBox(width: size * 1.2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tenant.name, style: AppTextStyle.bodyBold(size, color: navyDark)),
                  if (tenant.host.isNotEmpty && tenant.host != tenant.name) ...[
                    SizedBox(height: size * 0.2),
                    Text(tenant.host, style: AppTextStyle.small(size, color: Colors.grey.shade600)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: navyMid, size: size * 2.2),
          ],
        ),
      ),
    ),
  );
}
