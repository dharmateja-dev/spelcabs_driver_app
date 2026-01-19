import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/utils/app_logger.dart';
import 'package:driver/constant/constant.dart';

class Preferences {
  /// ================= KEYS =================
  static const String isFinishOnBoardingKey = "isFinishOnBoardingKey";
  static const String languageCodeKey = "languageCodeKey"; // stores JSON
  static const String themeKey = "themeKey";
  static const String contactList = "contactList";

  /// ================= INSTANCE =================
  static late SharedPreferences pref;

  /// ================= INIT =================
  static Future<void> initPref() async {
    pref = await SharedPreferences.getInstance();
  }

  /// ================= BOOLEAN =================
  static bool getBoolean(String key) {
    return pref.getBool(key) ?? false;
  }

  static Future<void> setBoolean(String key, bool value) async {
    await pref.setBool(key, value);
  }

  /// ================= STRING =================

  /// ❗ Use ONLY when empty string is acceptable
  static String getString(String key) {
    return pref.getString(key) ?? "";
  }

  /// ✅ Use this for JSON / optional values
  static String? getNullableString(String key) {
    return pref.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    await pref.setString(key, value);
  }

  /// ================= INTEGER =================
  static int getInt(String key) {
    return pref.getInt(key) ?? 0;
  }

  static Future<void> setInt(String key, int value) async {
    await pref.setInt(key, value);
  }

  /// ================= JSON HELPERS =================

  /// Safe JSON getter (Map)
  static Map<String, dynamic>? getJson(String key) {
    try {
      final String? raw = getNullableString(key);
      if (raw == null || raw.trim().isEmpty) return null;
      if (!raw.trim().startsWith('{')) return null;

      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (e) {
      AppLogger.error(
        "Preferences: Failed to decode JSON for key: $key",
        tag: "Preferences",
        error: e,
      );
    }
    return null;
  }

  static Future<void> setJson(String key, Map<String, dynamic> value) async {
    await setString(key, jsonEncode(value));
  }

  /// ================= CLEAR =================
  static Future<void> clearSharPreference() async {
    await pref.clear();
  }

  static Future<void> clearKeyData(String key) async {
    await pref.remove(key);
  }

  /// ================= DRIVER USER =================
  static Future<void> saveDriverUserData(DriverUserModel driverUser) async {
    try {
      await setJson(
        Constant.driverUserModelKey,
        driverUser.toJson(),
      );

      await setBoolean(Constant.isLoggedInKey, true);
      await setString(Constant.driverIdKey, driverUser.id.toString());
      await setString(Constant.driverNameKey, driverUser.fullName ?? "");
      await setString(Constant.driverEmailKey, driverUser.email ?? "");
      await setString(Constant.driverPhoneKey, driverUser.phoneNumber ?? "");
      await setString(Constant.driverImageKey, driverUser.profilePic ?? "");

      AppLogger.info(
        "Driver user data saved. ID: ${driverUser.id}",
        tag: "Preferences",
      );
    } catch (e, s) {
      AppLogger.error(
        "Failed to save driver user data",
        tag: "Preferences",
        error: e,
        stackTrace: s,
      );
    }
  }

  static DriverUserModel? getDriverUserData() {
    try {
      final Map<String, dynamic>? json = getJson(Constant.driverUserModelKey);

      if (json != null) {
        return DriverUserModel.fromJson(json);
      }
    } catch (e, s) {
      AppLogger.error(
        "Failed to retrieve driver user data",
        tag: "Preferences",
        error: e,
        stackTrace: s,
      );
    }
    return null;
  }

  static Future<void> clearDriverUserData() async {
    AppLogger.info(
      "Clearing all driver user data",
      tag: "Preferences",
    );

    await clearKeyData(Constant.driverUserModelKey);
    await clearKeyData(Constant.isLoggedInKey);
    await clearKeyData(Constant.driverIdKey);
    await clearKeyData(Constant.driverNameKey);
    await clearKeyData(Constant.driverEmailKey);
    await clearKeyData(Constant.driverPhoneKey);
    await clearKeyData(Constant.driverImageKey);
  }
}
