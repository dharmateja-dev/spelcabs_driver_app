import 'dart:convert';
import 'package:driver/utils/app_logger.dart';
import 'package:driver/utils/preferences.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/utils/fire_store_utils.dart';

class UserDataService {
  static final _memoryCache = <String, UserModel>{};
  static const _maxRetries = 5;
  static const _retryDelay = Duration(seconds: 1);

  static Future<UserModel?> getUser(String userId) async {
    // 1. Check memory cache first
    if (_memoryCache.containsKey(userId)) {
      return _memoryCache[userId];
    }

    // 2. Check persistent cache
    final cachedUser = _getCachedUser(userId);
    if (cachedUser != null) {
      _memoryCache[userId] = cachedUser;
      return cachedUser;
    }

    // 3. Fetch from Firestore with retries
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        AppLogger.debug("Fetching user $userId (attempt $attempt/$_maxRetries)");
        final user = await FireStoreUtils.getCustomer(userId);

        if (user != null) {
          _cacheUser(userId, user);
          return user;
        }
      } catch (e, s) {
        AppLogger.error("User fetch failed (attempt $attempt): $e",
            error: e, stackTrace: s);
      }

      // Delay between retries
      if (attempt < _maxRetries) await Future.delayed(_retryDelay);
    }

    return null;
  }

  static UserModel? _getCachedUser(String userId) {
    try {
      final cachedData = Preferences.getString("user_$userId");
      if (cachedData != null) {
        return UserModel.fromJson(jsonDecode(cachedData));
      }
    } catch (e, s) {
      AppLogger.error("Cache read error: $e", error: e, stackTrace: s);
    }
    return null;
  }

  static void _cacheUser(String userId, UserModel user) {
    try {
      // Update memory cache
      _memoryCache[userId] = user;

      // Update persistent cache
      Preferences.setString("user_$userId", jsonEncode(user.toJson()));
    } catch (e, s) {
      AppLogger.error("Cache write error: $e", error: e, stackTrace: s);
    }
  }
}