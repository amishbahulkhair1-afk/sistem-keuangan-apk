import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _baseUrlKey = 'api_base_url';

  // Default server url: 10.0.2.2 is Android emulator localhost, 127.0.0.1 for desktop/web
  static const String defaultBaseUrl = 'http://10.0.2.2:8000';

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
    _baseUrl = prefs.getString(_baseUrlKey) ?? (kIsWeb ? 'http://localhost:8000' : defaultBaseUrl);
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
