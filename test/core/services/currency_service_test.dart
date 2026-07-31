// Regression cover for P3.7: the selected currency isn't a secret and
// previously lived in Keychain-backed secure storage — moved to
// SharedPreferences.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/services/currency_service.dart';

void main() {
  Future<CurrencyService> freshService() async {
    SharedPreferences.setMockInitialValues({});
    return CurrencyService(await SharedPreferences.getInstance());
  }

  test('defaults to USD when nothing is stored', () async {
    final service = await freshService();
    expect(await service.loadCurrencyCode(), 'USD');
  });

  test('round-trips a supported currency code through SharedPreferences', () async {
    final service = await freshService();
    await service.saveCurrencyCode('eur');
    expect(await service.loadCurrencyCode(), 'EUR');
  });

  test('an unsupported stored code falls back to the default', () async {
    SharedPreferences.setMockInitialValues({'app_currency_code': 'XXX'});
    final service = CurrencyService(await SharedPreferences.getInstance());
    expect(await service.loadCurrencyCode(), 'USD');
  });

  test('savings currency defaults to the given fallback and round-trips independently '
      'of the app currency', () async {
    final service = await freshService();
    await service.saveCurrencyCode('EUR');
    expect(await service.loadSavingsCurrencyCode(fallback: 'GBP'), 'GBP');

    await service.saveSavingsCurrencyCode('JPY');
    expect(await service.loadSavingsCurrencyCode(), 'JPY');
    expect(await service.loadCurrencyCode(), 'EUR');
  });
}
