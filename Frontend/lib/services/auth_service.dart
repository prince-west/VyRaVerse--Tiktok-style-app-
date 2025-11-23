import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// AuthService - Wrapper for authentication state management
/// Uses ApiService for actual authentication, only stores token (not passwords)
class AuthService {
  static const String _tokenKey = 'auth_token';

  final ApiService _apiService = ApiService();

  /// Check if user is logged in by verifying token exists
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token == null || token.isEmpty) {
        return false;
      }
      // Optionally verify token is still valid by checking profile
      try {
        await _apiService.getProfile();
        return true;
      } catch (e) {
        // Token invalid, clear it
        await signOut();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Sign out - clears authentication token
  Future<void> signOut() async {
    try {
      await _apiService.signOut();
    } catch (e) {
      // Even if API call fails, clear local token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    }
  }
}

