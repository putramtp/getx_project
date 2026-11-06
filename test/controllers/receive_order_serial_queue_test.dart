import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getx_project/app/data/models/serial_confirm_summary_model.dart';
import 'package:getx_project/app/data/providers/receive_order_provider.dart';
import 'package:getx_project/app/modules/receive_order/controllers/receive_order_home_controller.dart';
import 'package:getx_project/app/modules/receive_order/controllers/receive_order_list_controller.dart';
import 'package:getx_project/app/services/auth_service.dart';
import 'package:getx_project/app/services/network_service.dart';

class _FakeReceiveOrderProvider extends ReceiveOrderProvider {
  SerialConfirmSummary summary = const SerialConfirmSummary(pendingOrders: 2, pendingLabels: 5, windowDays: 30);
  int summaryCalls = 0;

  @override
  Future<SerialConfirmSummary> getSerialConfirmSummary() async {
    summaryCalls++;
    return summary;
  }
}

/// Always online, without touching connectivity_plus or DNS.
class _OnlineNetworkService extends NetworkService {
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> checkConnection() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeReceiveOrderProvider provider;

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('receive_order_serial_queue_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => dir.path,
    );
    await GetStorage.init();
    Get.put(AuthService());
    Get.put<NetworkService>(_OnlineNetworkService());
  });

  setUp(() {
    provider = _FakeReceiveOrderProvider();
    Get.put<ReceiveOrderProvider>(provider);
  });

  tearDown(() => Get.delete<ReceiveOrderProvider>(force: true));

  test('the home loads the serial-confirm summary', () async {
    final controller = ReceiveOrderHomeController(); // not Get.put: no onInit load

    await controller.loadSerialSummary();

    expect(provider.summaryCalls, 1);
    expect(controller.serialSummary.value?.pendingOrders, 2);
    expect(controller.serialSummary.value?.pendingLabels, 5);
  });

  test('the pending queue asks the list for serial_status=pending', () {
    final controller = ReceiveOrderListController(pendingSerialOnly: true);

    expect(controller.buildParams()['serial_status'], 'pending');
  });

  test('the receiving history sends no serial_status', () {
    final controller = ReceiveOrderListController();

    expect(controller.buildParams().containsKey('serial_status'), isFalse);
  });
}
