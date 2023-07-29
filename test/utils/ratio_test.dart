import 'package:citizenwallet/utils/ratio.dart';
import 'package:test/test.dart';

void main() {
  group('progressiveClamp', () {
    test('should return min when ratio is 1', () {
      expect(progressiveClamp(0, 100, 1), equals(0));
      expect(progressiveClamp(-10, 10, 1), equals(-10));
      expect(progressiveClamp(-100, -50, 1), equals(-100));
    });

    test('should return max when ratio is 0', () {
      expect(progressiveClamp(0, 100, 0), equals(100));
      expect(progressiveClamp(-10, 10, 0), equals(10));
      expect(progressiveClamp(-100, -50, 0), equals(-50));
    });

    test('should return correct value when ratio is between 0 and 1', () {
      expect(progressiveClamp(0, 100, 0.5), equals(50));
      expect(progressiveClamp(-10, 10, 0.25), equals(5));
      expect(progressiveClamp(-100, -50, 0.75), equals(-87.5));
    });

    test('should return min when max is less than min', () {
      expect(progressiveClamp(100, 0, 0.5), equals(100));
      expect(progressiveClamp(10, -10, 0.25), equals(10));
      expect(progressiveClamp(-50, -100, 0.75), equals(-50));
    });
  });
}
