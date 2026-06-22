import 'package:shared_preferences/shared_preferences.dart';

/// Thin synchronous-looking wrapper around [SharedPreferences].
///
/// Call `Prefs.init()` once in `main()` before `runApp`, then use the
/// static getters/setters anywhere in the app without passing instances
/// around.
abstract class Prefs {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<bool> setBool(String key, bool value) =>
      _prefs.setBool(key, value);

  static bool getBool(String key) => _prefs.getBool(key) ?? false;

  static Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  static String? getString(String key) => _prefs.getString(key);

  static Future<bool> remove(String key) => _prefs.remove(key);
}
