import 'package:basic_crud_flutter/core/storage/app_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppPrefs', () {
    test('hasSeenOnboarding returns false when flag is absent', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPrefs.create();
      expect(prefs.hasSeenOnboarding(), isFalse);
    });

    test('hasSeenOnboarding returns true after markOnboardingSeen', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPrefs.create();
      await prefs.markOnboardingSeen();
      expect(prefs.hasSeenOnboarding(), isTrue);
    });

    test('hasSeenOnboarding returns true when flag already true', () async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      final prefs = await AppPrefs.create();
      expect(prefs.hasSeenOnboarding(), isTrue);
    });

    test('getQuotaMb returns 250 by default', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPrefs.create();
      expect(prefs.getQuotaMb(), 250);
    });

    test('setQuotaMb persists the value', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPrefs.create();
      await prefs.setQuotaMb(500);
      expect(prefs.getQuotaMb(), 500);
    });

    test('getQuotaMb returns stored value when present', () async {
      SharedPreferences.setMockInitialValues({'quota_mb': 1024});
      final prefs = await AppPrefs.create();
      expect(prefs.getQuotaMb(), 1024);
    });

    test('setQuotaMb rejects non-positive values', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPrefs.create();
      expect(() => prefs.setQuotaMb(0), throwsArgumentError);
      expect(() => prefs.setQuotaMb(-10), throwsArgumentError);
    });

    test('hasSeenDemoPrompt defaults to false', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPrefs.create();
      expect(prefs.hasSeenDemoPrompt(), isFalse);
    });

    test('markDemoPromptSeen flips the flag', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPrefs.create();
      await prefs.markDemoPromptSeen();
      expect(prefs.hasSeenDemoPrompt(), isTrue);
    });

    test('getActiveTrekSessionId returns null by default', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPrefs.create();
      expect(prefs.getActiveTrekSessionId(), isNull);
    });

    test('setActiveTrekSessionId persists then null clears', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPrefs.create();
      await prefs.setActiveTrekSessionId('s1');
      expect(prefs.getActiveTrekSessionId(), 's1');
      await prefs.setActiveTrekSessionId(null);
      expect(prefs.getActiveTrekSessionId(), isNull);
    });
  });
}
