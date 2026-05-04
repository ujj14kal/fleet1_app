import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages the 10-day inactivity session window.
class SessionService {
  static const String _lastActiveKey = 'fleet1_last_active';
  static const String _userRoleKey   = 'fleet1_user_role';
  static const int    _inactiveDays  = 10;

  /// Call on every user action to keep the session alive.
  static Future<void> touch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Returns true if the Supabase session exists AND last activity < 10 days.
  static Future<bool> isSessionValid() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastActive = prefs.getInt(_lastActiveKey);
    if (lastActive == null) return false;

    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastActive),
    );
    return diff.inDays < _inactiveDays;
  }

  /// Save the user's role locally for fast routing on next open.
  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
    await touch();
  }

  static Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastActiveKey);
    await prefs.remove(_userRoleKey);
  }
}
