import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Single source of truth for the authenticated user.
/// Loaded once on app start from SharedPreferences; updated on login/logout.
/// All screens that show user-specific data must consume this.
class UserAuthProvider extends ChangeNotifier {
  String? _name;
  String? _email;
  String? _role;
  int? _userId;
  int? _providerId;
  bool _isLoggedIn = false;
  bool _initialized = false;

  // ── Getters ──────────────────────────────────────────────────────────────

  String get name => _name ?? '';
  String get email => _email ?? '';
  String get role => _role ?? '';
  int? get userId => _userId;
  int? get providerId => _providerId;
  bool get isLoggedIn => _isLoggedIn;
  bool get isServiceUser => _role == 'service_user';
  bool get isProvider => _role == 'service_provider';
  bool get initialized => _initialized;

  /// First letter of the user's name for avatar placeholders.
  String get initial =>
      _name != null && _name!.isNotEmpty ? _name!.substring(0, 1) : '؟';

  // ── Bootstrap: called once from main() ───────────────────────────────────

  Future<void> loadFromStorage() async {
    final token = await ApiService.getAccessToken();
    if (token == null) {
      _initialized = true;
      notifyListeners();
      return;
    }
    _email = await ApiService.getEmail();
    _role = await ApiService.getRole();
    _userId = await ApiService.getUserId();
    _providerId = await ApiService.getProviderId();
    _isLoggedIn = true;
    _initialized = true;
    notifyListeners();
  }

  // ── Called after a successful login response ──────────────────────────────

  void onLoginSuccess({
    required String role,
    String? email,
    String? name,
    int? userId,
    int? providerId,
  }) {
    _role = role;
    _email = email ?? _email;
    _name = name ?? _name;
    _userId = userId ?? _userId;
    _providerId = providerId ?? _providerId;
    _isLoggedIn = true;
    notifyListeners();
  }

  /// Call this after loading the user profile from the API.
  void setProfile({required String name, String? email, String? address}) {
    _name = name;
    if (email != null) _email = email;
    notifyListeners();
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await ApiService.clearTokens();
    _name = null;
    _email = null;
    _role = null;
    _userId = null;
    _providerId = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
