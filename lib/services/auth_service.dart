import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _baseUrlKey = 'api_base_url';

  // Production server url
  static const String defaultBaseUrl = 'https://donasi.annuqayahlatee.id/backend_donasi';

  String _baseUrl = defaultBaseUrl;
  String? _token;
  UserModel? _currentUser;
  bool _isLoading = true;

  String get baseUrl => _baseUrl;
  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isLoading => _isLoading;

  AuthService() {
    init();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey);

    // Validasi URL tersimpan: jika kosong, bukan http/https, memiliki suffix /api atau /health,
    // atau masih menggunakan localhost/10.0.2.2 lama, reset ke defaultBaseUrl yang baru.
    if (savedUrl != null &&
        savedUrl.startsWith('http') &&
        !savedUrl.endsWith('/api') &&
        !savedUrl.endsWith('/health') &&
        !savedUrl.contains('localhost') &&
        !savedUrl.contains('10.0.2.2')) {
      _baseUrl = savedUrl;
    } else {
      _baseUrl = defaultBaseUrl;
      await prefs.setString(_baseUrlKey, defaultBaseUrl);
    }

    _token = prefs.getString(_tokenKey);

    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      } catch (e) {
        _currentUser = null;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setBaseUrl(String newUrl) async {
    _baseUrl = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl);
    notifyListeners();
  }

  Future<void> saveSession(String token, UserModel user) async {
    _token = token;
    _currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));

    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    notifyListeners();
  }
}
