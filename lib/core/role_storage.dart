import 'package:shared_preferences/shared_preferences.dart';
import 'user_role.dart';

class RoleStorage {
  static const _roleKey = 'user_role';

  static Future<void> saveRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.key);
  }

  static Future<UserRole?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_roleKey);
    return UserRoleX.fromKey(key);
  }

  static Future<void> clearRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
  }
}
