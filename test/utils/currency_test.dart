import 'package:citizenwallet/utils/currency.dart';
import 'package:test/test.dart';

void main() {
  group('formatCurrency', () {
    test('formats positive amount correctly', () {
      expect(
          formatCurrency(1234.56, 'USDC',
              decimalDigits: 2, factor: 1, isIncoming: true),
          '+ USDC 1,234.56');
    });

    test('formats negative amount correctly', () {
      expect(
          formatCurrency(-1234.56, 'USDC',
              decimalDigits: 2, factor: 1, isIncoming: false),
          '- USDC 1,234.56');
    });

    test('formats zero amount correctly', () {
      expect(
          formatCurrency(0, 'USDC', decimalDigits: 2, factor: 1), 'USDC 0.00');
    });
  });

  group('formatAmount', () {
    test('formats positive amount correctly', () {
      expect(
          formatAmount(1234.56, decimalDigits: 2, factor: 1, isIncoming: true),
          '+ 1,234.56');
    });

    test('formats negative amount correctly', () {
      expect(
          formatAmount(-1234.56,
              decimalDigits: 2, factor: 1, isIncoming: false),
          '- 1,234.56');
    });

    test('formats zero amount correctly', () {
      expect(formatAmount(0, decimalDigits: 2, factor: 1), '0.00');
    });
  });
}
