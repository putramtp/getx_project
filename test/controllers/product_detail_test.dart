import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getx_project/app/data/models/product_detail_model.dart';
import 'package:getx_project/app/data/models/product_summary_model.dart';
import 'package:getx_project/app/data/providers/product_provider.dart';
import 'package:getx_project/app/modules/product/controllers/product_detail.controller.dart';
import 'package:getx_project/app/modules/product/views/product_detail_view.dart';
import 'package:getx_project/app/services/auth_service.dart';
import 'package:getx_project/app/services/network_service.dart';

import '../widgets/pump_ui.dart';

/// Always online, without touching connectivity_plus or DNS.
class _OnlineNetworkService extends NetworkService {
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> checkConnection() async {}
}

/// Fails until [failing] is turned off.
class _FakeProductProvider extends ProductProvider {
  bool failing = true;
  int calls = 0;

  @override
  Future<ProductDetailModel> getProductDetail(int productId) async {
    calls++;
    if (failing) throw Exception('No response from server.');
    return ProductDetailModel.fromJson({
      'id': productId,
      'upc': 'UPC-777',
      'manage_expired': true,
      'price_sell': '2500',
    });
  }
}

/// A failed load must offer Retry — not a page of defaults ("Expired: No",
/// "Rp -") that reads as the product's own data.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeProductProvider provider;
  final product = ProductSummaryModel.fromJson({'item_id': 42, 'item_name': 'Valve', 'item_code': 'SKU-42'});

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('product_detail_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => dir.path,
    );
    await GetStorage.init();
    Get.put(AuthService());
    Get.put<NetworkService>(_OnlineNetworkService());
  });

  setUp(() {
    provider = _FakeProductProvider();
    Get.put<ProductProvider>(provider);
  });
  tearDown(() {
    Get.delete<ProductDetailController>(force: true);
    Get.delete<ProductProvider>(force: true);
  });

  /// Opens the page the way the app does: a named route whose binding puts
  /// the controller, with the product as the route's arguments.
  Future<void> openDetail(WidgetTester t) async {
    await pumpUi(
      t,
      const Scaffold(),
      pages: [
        GetPage(
          name: '/product-detail',
          page: () => const ProductDetailView(),
          binding: BindingsBuilder(() => Get.lazyPut(() => ProductDetailController())),
        ),
      ],
    );
    Get.toNamed('/product-detail', arguments: product);
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> drainSnackbars(WidgetTester t) async {
    Get.closeAllSnackbars();
    await t.pumpAndSettle();
  }

  testWidgets('a failed load shows Retry, not default values', (t) async {
    await openDetail(t);

    expect(Get.find<ProductDetailController>().hasError.value, isTrue);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Expired'), findsNothing);
    expect(find.text('Basic Information'), findsNothing);
    await drainSnackbars(t);
  });

  testWidgets('Retry loads the product once the server answers', (t) async {
    await openDetail(t);
    await drainSnackbars(t);

    provider.failing = false;
    await t.tap(find.text('Retry'));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }

    expect(provider.calls, 2);
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Basic Information'), findsOneWidget);
    expect(find.text('UPC-777'), findsOneWidget);
  });
}
