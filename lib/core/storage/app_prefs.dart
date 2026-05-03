import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const _kOnboardingSeen = 'onboarding_seen';
  static const _kQuotaMb = 'quota_mb';
  static const int _kQuotaMbDefault = 250;
  static const _kDemoPromptSeen = 'demo_prompt_seen';
  static const _kActiveTrekSessionId = 'active_trek_session_id';

  final SharedPreferences _prefs;

  AppPrefs._(this._prefs);

  static Future<AppPrefs> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPrefs._(prefs);
  }

  bool hasSeenOnboarding() => _prefs.getBool(_kOnboardingSeen) ?? false;

  Future<void> markOnboardingSeen() =>
      _prefs.setBool(_kOnboardingSeen, true);

  int getQuotaMb() => _prefs.getInt(_kQuotaMb) ?? _kQuotaMbDefault;

  Future<void> setQuotaMb(int mb) {
    if (mb <= 0) {
      throw ArgumentError.value(mb, 'mb', 'quota must be positive');
    }
    return _prefs.setInt(_kQuotaMb, mb);
  }

  bool hasSeenDemoPrompt() => _prefs.getBool(_kDemoPromptSeen) ?? false;

  Future<void> markDemoPromptSeen() =>
      _prefs.setBool(_kDemoPromptSeen, true);

  String? getActiveTrekSessionId() => _prefs.getString(_kActiveTrekSessionId);

  Future<void> setActiveTrekSessionId(String? id) {
    if (id == null) {
      return _prefs.remove(_kActiveTrekSessionId);
    }
    return _prefs.setString(_kActiveTrekSessionId, id);
  }
}
