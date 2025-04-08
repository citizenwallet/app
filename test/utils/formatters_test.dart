import 'package:citizenwallet/utils/formatters.dart';
import 'package:flutter/cupertino.dart';
import 'package:test/test.dart';

void main() {
  test('AmountFormatter should allow valid input', () {
    final formatter = AmountFormatter();
    const oldValue = TextEditingValue(text: '123.45');
    const newValue = TextEditingValue(text: '123.45');
    final updatedValue = formatter.formatEditUpdate(oldValue, newValue);
    expect(updatedValue, equals(newValue));
  });

  test('AmountFormatter should allow empty input', () {
    final formatter = AmountFormatter();
    const oldValue = TextEditingValue(text: '');
    const newValue = TextEditingValue(text: '');
    final updatedValue = formatter.formatEditUpdate(oldValue, newValue);
    expect(updatedValue, equals(newValue));
  });

  test('AmountFormatter should convert commas to decimals', () {
    final formatter = AmountFormatter();
    const oldValue = TextEditingValue(text: '123,456');
    const newValue = TextEditingValue(text: '123.456');
    final updatedValue = formatter.formatEditUpdate(oldValue, newValue);
    expect(updatedValue, equals(oldValue));
  });

  test('AmountFormatter should not allow invalid input', () {
    final formatter = AmountFormatter();
    const oldValue = TextEditingValue(text: '&(&^*123.456');
    const newValue = TextEditingValue(text: '123.456');
    final updatedValue = formatter.formatEditUpdate(oldValue, newValue);
    expect(updatedValue, equals(oldValue));
  });

  test('AmountFormatter should not allow multiple decimals', () {
    final formatter = AmountFormatter();
    const oldValue = TextEditingValue(text: '123.456.12');
    const newValue = TextEditingValue(text: '123.456');
    final updatedValue = formatter.formatEditUpdate(oldValue, newValue);
    expect(updatedValue, equals(oldValue));
  });

  test('cleanNameString should clean the string', () {
    const name = "This is a test string! @ 123 \u00E9";
    final cleaned = cleanNameString(name);
    expect(cleaned, equals("This is a test string   é"));
  });
}
