// Regression cover for P3.7: the selected language isn't a secret and
// previously lived in Keychain-backed secure storage — moved to
// SharedPreferences.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/services/locale_service.dart';

void main() {
  Future<LocaleService> freshService() async {
    SharedPreferences.setMockInitialValues({});
    return LocaleService(await SharedPreferences.getInstance());
  }

  test('defaults to English when nothing is stored', () async {
    final service = await freshService();
    expect(await service.loadLanguageCode(), 'en');
  });

  test('round-trips a supported language code through SharedPreferences', () async {
    final service = await freshService();
    await service.saveLanguageCode('de');
    expect(await service.loadLanguageCode(), 'de');
  });

  test('an unsupported stored code falls back to the default', () async {
    SharedPreferences.setMockInitialValues({'app_language_code': 'xx'});
    final service = LocaleService(await SharedPreferences.getInstance());
    expect(await service.loadLanguageCode(), 'en');
  });

  test('saveLanguageCode normalizes to lowercase', () async {
    final service = await freshService();
    await service.saveLanguageCode('FR');
    expect(await service.loadLanguageCode(), 'fr');
  });
}
