import 'package:shared_preferences/shared_preferences.dart';

/// Persists demo login without Firebase (see [AppConfig.useDemoAuth]).
class DemoSession {
  DemoSession._();
  static final DemoSession instance = DemoSession._();

  static const _kLoggedIn = 'demo_logged_in';
  static const _kUid = 'demo_uid';
  static const _kPhone = 'demo_phone';
  static const _kPendingPhone = 'demo_pending_phone';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get isLoggedIn => _prefs?.getBool(_kLoggedIn) ?? false;
  String? get uid => _prefs?.getString(_kUid);
  String? get phone => _prefs?.getString(_kPhone);
  String? get pendingPhone => _prefs?.getString(_kPendingPhone);

  Future<void> setPendingPhone(String phone) async {
    await _prefs?.setString(_kPendingPhone, phone);
  }

  Future<void> clearPendingPhone() async {
    await _prefs?.remove(_kPendingPhone);
  }

  Future<void> signIn({required String uid, required String phone}) async {
    await _prefs?.setBool(_kLoggedIn, true);
    await _prefs?.setString(_kUid, uid);
    await _prefs?.setString(_kPhone, phone);
    await clearPendingPhone();
  }

  Future<void> signOut() async {
    await _prefs?.setBool(_kLoggedIn, false);
    await _prefs?.remove(_kUid);
    await _prefs?.remove(_kPhone);
    await clearPendingPhone();
  }
}
