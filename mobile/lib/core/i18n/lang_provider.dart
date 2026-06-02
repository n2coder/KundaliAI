import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';

const _prefsKey = 'app_lang';

/// App-wide UI + content language ('en' | 'hi').
///
/// - Persists the user's explicit choice on-device (shared_preferences).
/// - Adopts the account language from /auth/me until the user picks one here.
/// - On change, syncs the preference to the backend (so AI content is generated
///   in the chosen language) and invalidates cached content providers.
class LangNotifier extends StateNotifier<String> {
  LangNotifier(this._ref) : super('en') {
    _load();
    _ref.listen<AsyncValue<UserModel?>>(authProvider, (_, next) {
      final u = next.valueOrNull;
      if (u != null) adopt(u.language);
    });
  }

  final Ref _ref;
  bool _userChose = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored == 'en' || stored == 'hi') {
      _userChose = true;
      state = stored!;
    }
  }

  /// Use the account's saved language unless the user explicitly chose one here.
  void adopt(String lang) {
    if (!_userChose && (lang == 'en' || lang == 'hi')) {
      state = lang;
    }
  }

  Future<void> setLang(String lang) async {
    if (lang != 'en' && lang != 'hi') return;
    if (lang == state && _userChose) return;
    _userChose = true;
    state = lang;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, lang);

    // Persist to the account so AI content (horoscope/chat/insights/today) is
    // generated in this language, and refresh the cached user.
    try {
      final updated =
          await _ref.read(authRepoProvider).updateMe({'language': lang});
      _ref.read(authProvider.notifier).updateUser(updated);
    } catch (_) {
      // Not signed in / offline — the local toggle still applies.
    }

    // Drop cached AI content so it refetches in the new language.
    _ref.invalidate(todayProvider);
    _ref.invalidate(dailyHoroscopeProvider);
    _ref.invalidate(weeklyHoroscopeProvider);
    _ref.invalidate(monthlyHoroscopeProvider);
    _ref.invalidate(allInsightsProvider);
  }

  void toggle() => setLang(state == 'en' ? 'hi' : 'en');
}

final langProvider =
    StateNotifierProvider<LangNotifier, String>((ref) => LangNotifier(ref));
