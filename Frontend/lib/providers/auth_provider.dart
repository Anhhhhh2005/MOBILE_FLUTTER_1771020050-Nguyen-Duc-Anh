import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class AuthProvider extends ChangeNotifier {
  UserInfo? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  UserInfo? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  bool get isInitialized => _isInitialized;

  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isTreasurer => _user?.isTreasurer ?? false;
  bool get isReferee => _user?.isReferee ?? false;

  Future<void> init() async {
    if (_isInitialized) return;

    await apiService.init();

    if (apiService.hasToken) {
      try {
        final userData = await apiService.getCurrentUser();
        _user = UserInfo.fromJson(userData);

        // Connect to SignalR
        await signalRService.connect(await _getToken() ?? '');
      } catch (e) {
        // Token invalid, clear it
        await apiService.clearToken();
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<String?> _getToken() async {
    // This is a simplified version - in production, get token from storage
    return null;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.login(email, password);
      final authResponse = AuthResponse.fromJson(response);

      await apiService.setToken(authResponse.token);
      _user = authResponse.user;

      // Connect to SignalR
      await signalRService.connect(authResponse.token);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.register(email, password, fullName);
      final authResponse = AuthResponse.fromJson(response);

      await apiService.setToken(authResponse.token);
      _user = authResponse.user;

      // Connect to SignalR
      await signalRService.connect(authResponse.token);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await apiService.clearToken();
    await signalRService.disconnect();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (!isLoggedIn) return;

    try {
      final userData = await apiService.getCurrentUser();
      _user = UserInfo.fromJson(userData);
      notifyListeners();
    } catch (e) {
      // Ignore errors
    }
  }

  String _parseError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }
}
