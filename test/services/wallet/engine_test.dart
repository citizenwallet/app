import 'package:test/test.dart';
import 'package:citizenwallet/services/engine/utils.dart';

void main() {
  group('buildQueryParams', () {
    test('builds query params with single data list', () {
      final data = [
        {'key': 'name', 'value': 'John Doe'},
        {'key': 'age', 'value': '30'},
      ];

      final result = buildQueryParams(data);

      expect(result, 'data.name=John%20Doe&data.age=30');
    });

    test('builds query params with data and data2 lists', () {
      final data = [
        {'key': 'name', 'value': 'John Doe'},
        {'key': 'age', 'value': '30'},
      ];
      final data2 = [
        {'key': 'city', 'value': 'New York'},
        {'key': 'country', 'value': 'USA'},
      ];

      final result = buildQueryParams(data, or: data2);

      expect(result,
          'data.name=John%20Doe&data.age=30&data2.city=New%20York&data2.country=USA');
    });

    test('handles empty lists', () {
      final result = buildQueryParams([]);

      expect(result, '');
    });
  });
}
