import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getx_project/app/data/models/outflow_request_customer_model.dart';
import 'package:getx_project/app/data/models/product_brand_model.dart';
import 'package:getx_project/app/data/models/purchase_order_supplier_model.dart';
import 'package:getx_project/app/data/providers/outflow_order_provider.dart';
import 'package:getx_project/app/data/providers/product_provider.dart';
import 'package:getx_project/app/data/providers/receive_order_provider.dart';
import 'package:getx_project/app/modules/outflow_order/controllers/outflow_order_by_customer_controller.dart';
import 'package:getx_project/app/modules/product-brand/controllers/product_by_brand_controller.dart';
import 'package:getx_project/app/modules/receive_order/controllers/receive_order_by_supplier_controller.dart';
import 'package:getx_project/app/services/auth_service.dart';
import 'package:getx_project/app/services/network_service.dart';

/// Always online, without touching connectivity_plus or DNS.
class _OnlineNetworkService extends NetworkService {
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> checkConnection() async {}
}

Map<String, dynamic> _target(int id, String code, String name) =>
    {'id': id, 'code': code, 'name': name, 'received': 0, 'total': 1};

/// The server answers its own order; tests change [rows] between loads.
class _FakeOutflowProvider extends OutflowOrderProvider {
  List<Map<String, dynamic>> rows = [];

  @override
  Future<List<OrCustomerModel>> getCustomers() async => rows.map(OrCustomerModel.fromJson).toList();
}

class _FakeReceiveProvider extends ReceiveOrderProvider {
  List<Map<String, dynamic>> rows = [];

  @override
  Future<List<PoSupplierModel>> getSuppliers() async => rows.map(PoSupplierModel.fromJson).toList();
}

Map<String, dynamic> _product(int id, String name) =>
    {'item_id': id, 'item_name': name, 'item_code': 'SKU-$id', 'qty_remaining': 20};

/// Two pages: the first without a cursor, the next with `cursor: 'p2'`.
class _FakeProductProvider extends ProductProvider {
  @override
  Future<Map<String, dynamic>> getProductSummariesByBrand({required int brandId, String? cursor}) async =>
      cursor == null
          ? {
              'data': [_product(1, 'Valve B'), _product(2, 'Pump D')],
              'next_cursor': 'p2',
            }
          : {
              'data': [_product(3, 'Valve A'), _product(4, 'Pump C')],
              'next_cursor': null,
            };
}

/// The lists that search and sort on the device: a reload (back from a
/// submit, pull to refresh) or a next page must keep the search still shown in
/// the box and the order the Sort button shows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('list_search_sort_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => dir.path,
    );
    await GetStorage.init();
    Get.put(AuthService());
    Get.put<NetworkService>(_OnlineNetworkService());
  });

  group('By Customer (and By Work Order)', () {
    late _FakeOutflowProvider provider;

    setUp(() {
      provider = _FakeOutflowProvider()
        ..rows = [_target(1, 'C-01', 'Beta'), _target(2, 'C-02', 'Acme North'), _target(3, 'C-03', 'Acme South')];
      Get.put<OutflowOrderProvider>(provider);
    });
    tearDown(() => Get.delete<OutflowOrderProvider>(force: true));

    test('a reload keeps the submitted search', () async {
      final controller = OutflowOrderByCustomerController(); // not Get.put: no onInit load
      await controller.loadCustomers();

      controller.onSearchChanged('acme');
      expect(controller.filteredCustomers.map((c) => c.name), ['Acme North', 'Acme South']);

      provider.rows = [...provider.rows, _target(4, 'C-04', 'Acme East')];
      await controller.loadCustomers();

      expect(controller.filteredCustomers.map((c) => c.name), ['Acme North', 'Acme South', 'Acme East']);
    });

    test('a reload keeps the order Sort set; before Sort, the server order stands', () async {
      final controller = OutflowOrderByCustomerController();
      await controller.loadCustomers();
      expect(controller.filteredCustomers.map((c) => c.name), ['Beta', 'Acme North', 'Acme South']);

      controller.toggleSort(); // Z→A
      expect(controller.filteredCustomers.map((c) => c.name), ['Beta', 'Acme South', 'Acme North']);

      await controller.loadCustomers();
      expect(controller.isAscending.value, isFalse);
      expect(controller.filteredCustomers.map((c) => c.name), ['Beta', 'Acme South', 'Acme North']);
    });

    test('search matches the code too, and clearing it shows every target', () async {
      final controller = OutflowOrderByCustomerController();
      await controller.loadCustomers();

      controller.onSearchChanged('c-01');
      expect(controller.filteredCustomers.map((c) => c.name), ['Beta']);

      controller.onSearchChanged('');
      expect(controller.filteredCustomers, hasLength(3));
    });
  });

  group('By Supplier', () {
    late _FakeReceiveProvider provider;

    setUp(() {
      provider = _FakeReceiveProvider()
        ..rows = [_target(1, 'S-01', 'Delta'), _target(2, 'S-02', 'Alpha Steel'), _target(3, 'S-03', 'Alpha Wire')];
      Get.put<ReceiveOrderProvider>(provider);
    });
    tearDown(() => Get.delete<ReceiveOrderProvider>(force: true));

    test('a reload keeps the search and the sort', () async {
      final controller = ReceiveOrderBySupplierController();
      await controller.loadSuppliers();

      controller.onSearchChanged('alpha');
      controller.toggleSort(); // Z→A
      expect(controller.filteredSuppliers.map((s) => s.name), ['Alpha Wire', 'Alpha Steel']);

      await controller.loadSuppliers();

      expect(controller.filteredSuppliers.map((s) => s.name), ['Alpha Wire', 'Alpha Steel']);
    });
  });

  group('Products per Brand (and per Category)', () {
    setUp(() => Get.put<ProductProvider>(_FakeProductProvider()));
    tearDown(() => Get.delete<ProductProvider>(force: true));

    ProductByBrandController controller() =>
        ProductByBrandController()..currentBrand = ProductBrandModel(id: 9, name: 'Cape', initialCode: 'CP', slug: 'cape');

    test('a next page keeps the search instead of showing every product again', () async {
      final c = controller();
      await c.loadProducts();

      c.filterList('valve');
      await Future.delayed(const Duration(milliseconds: 350)); // the search debounce
      expect(c.filteredProductSummaries.map((p) => p.itemName), ['Valve B']);

      await c.loadMore();

      expect(c.filteredProductSummaries.map((p) => p.itemName), ['Valve B', 'Valve A']);
    });

    test('a next page is sorted in with the rows above', () async {
      final c = controller();
      await c.loadProducts();

      c.toggleSort(); // Z→A over what is loaded
      expect(c.filteredProductSummaries.map((p) => p.itemName), ['Valve B', 'Pump D']);

      await c.loadMore();

      expect(c.filteredProductSummaries.map((p) => p.itemName), ['Valve B', 'Valve A', 'Pump D', 'Pump C']);
    });
  });
}
