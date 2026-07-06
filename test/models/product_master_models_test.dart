import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/models/product_unit_model.dart';
import 'package:getx_project/app/data/models/product_category_model.dart';
import 'package:getx_project/app/data/models/product_brand_model.dart';

void main() {
  group('ProductUnitModel.fromJson', () {
    test('parses id/name/description', () {
      final unit = ProductUnitModel.fromJson({
        'id': 5,
        'name': 'Kilogram',
        'description': 'Weight unit',
      });
      expect(unit.id, 5);
      expect(unit.name, 'Kilogram');
      expect(unit.description, 'Weight unit');
    });

    test('defaults null description to empty string', () {
      final unit = ProductUnitModel.fromJson({'id': 1, 'name': 'Box'});
      expect(unit.description, '');
    });
  });

  group('ProductCategoryModel.fromJson', () {
    test('maps initial_code → initialCode', () {
      final cat = ProductCategoryModel.fromJson({
        'id': 2,
        'name': 'Electronics',
        'initial_code': 'EL',
        'slug': 'electronics',
      });
      expect(cat.id, 2);
      expect(cat.name, 'Electronics');
      expect(cat.initialCode, 'EL');
      expect(cat.slug, 'electronics');
    });
  });

  group('ProductBrandModel.fromJson', () {
    test('maps initial_code → initialCode', () {
      final brand = ProductBrandModel.fromJson({
        'id': 9,
        'name': 'Acme',
        'initial_code': 'AC',
        'slug': 'acme',
      });
      expect(brand.id, 9);
      expect(brand.name, 'Acme');
      expect(brand.initialCode, 'AC');
      expect(brand.slug, 'acme');
    });
  });
}
