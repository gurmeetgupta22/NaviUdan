import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user       => _user;
  bool       get isLoading  => _isLoading;
  String?    get error      => _error;
  bool       get isLoggedIn => _authService.isLoggedIn;
  String?    get uid        => _authService.currentUid;

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? v) { _error = v; notifyListeners(); }

  Future<void> loadUserProfile() async {
    final uid = _authService.currentUid;
    if (uid == null) return;
    _setLoading(true);
    try {
      final data = await ApiService.getProfile(uid);
      _user = UserModel.fromJson(data);
      _error = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> saveProfile(Map<String, dynamic> profileData) async {
    _setLoading(true);
    try {
      await ApiService.createProfile(profileData);
      await loadUserProfile();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final uid = _authService.currentUid;
    if (uid == null) return false;
    _setLoading(true);
    try {
      await ApiService.updateProfile(uid, data);
      await loadUserProfile();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
