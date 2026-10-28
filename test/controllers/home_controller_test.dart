import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getx_project/app/data/models/dashboard_model.dart';
import 'package:getx_project/app/data/models/stock_transaction_model.dart';
import 'package:getx_project/app/data/providers/home_provider.dart';
import 'package:getx_project/app/modules/home/controllers/home_controller.dart';
import 'package:getx_project/app/services/auth_service.dart';
import 'package:getx_project/app/services/network_service.dart';

/// Holds every request open until [releaseAll], recording which have started.
class _FakeHomeProvider extends HomeProvider {
  final started = <String>{};
  final _pending = <Completer<void>>[];

  Future<T> _hold<T>(String name, T value) async {
    started.add(name);
    final gate = Completer<void>();
    _pending.add(gate);
    await gate.future;
    return value;
  }

  void releaseAll() {
    for (final gate in _pending) {
      gate.complete();
    }
  }

  @override
  Future<DashboardModel> getDashboard({required int year}) => _hold(
        'dashboard',
        DashboardModel(product: 5, receiveOrder: 2, outflowOrder: 3, productUnique: 1, productOther: 4),
      );

  @override
  Future<List<StockTransactionModel>> getLatestTransaction({required int limit}) =>
      _hold('latest', <StockTransactionModel>[]);

  @override
  Future<int> getPendingDeliveryCount() => _hold('deliveries', 7);
}

/// Always online, without touching connectivity_plus or DNS.
class _OnlineNetworkService extends NetworkService {
  // Skips NetworkService.onInit, which subscribes to connectivity_plus.
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> checkConnection() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('home_controller_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => dir.path,
    );
    await GetStorage.init();
    Get.put(AuthService());
    Get.put<NetworkService>(_OnlineNetworkService());
  });

  test('reloadDashboard sends its three requests at the same time', () async {
    final provider = _FakeHomeProvider();
    Get.put<HomeProvider>(provider);
    final controller = HomeController(); // not Get.put: no auto-reload or timer

    final reload = controller.reloadDashboard();
    await pumpEventQueue();

    // Sequential awaits would have started only the dashboard request here.
    expect(provider.started, {'dashboard', 'latest', 'deliveries'});

    provider.releaseAll();
    await reload;
    expect(controller.dashboard.value.product, 5);
    expect(controller.pendingDeliveries.value, 7);
  });
}
