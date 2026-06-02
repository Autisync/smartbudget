import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/components/forms/form_validation.dart';

void main() {
  group('FormValidation', () {
    test('requiredText validates empty values', () {
      expect(FormValidation.requiredText('', 'required'), 'required');
      expect(FormValidation.requiredText('  ', 'required'), 'required');
      expect(FormValidation.requiredText('ok', 'required'), isNull);
    });

    test('positiveAmount parses grouped amount strings', () {
      expect(
        FormValidation.positiveAmount('1,250.75', 'empty', 'invalid'),
        isNull,
      );
      expect(
        FormValidation.positiveAmount('0', 'empty', 'invalid'),
        'invalid',
      );
      expect(
        FormValidation.positiveAmount('', 'empty', 'invalid'),
        'empty',
      );
    });

    test('parseDecimal supports currency-like strings', () {
      expect(FormValidation.parseDecimal(r'$ 2,499.90'), 2499.9);
      expect(FormValidation.parseDecimal('Kz 12,300.00'), 12300);
      expect(FormValidation.parseDecimal('abc'), isNull);
    });

    test('nonNegativeAmount validates negatives', () {
      expect(FormValidation.nonNegativeAmount('-1', 'invalid'), 'invalid');
      expect(FormValidation.nonNegativeAmount('0', 'invalid'), isNull);
      expect(FormValidation.nonNegativeAmount('1,900.25', 'invalid'), isNull);
    });
  });
}
