import 'dart:convert';
import 'dart:developer';

import 'package:driver/constant/constant.dart';
import 'package:driver/model/currency_model.dart';
import 'package:driver/model/language_model.dart';
import 'package:driver/utils/preferences.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/utils/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class GlobalSettingController extends GetxController {
  final RxBool isLoading = true.obs;
  final NotificationService notificationService = NotificationService();

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    log('🚀 Initializing app...');

    try {
      // Run all setup in parallel with timeout
      await Future.wait([
        _setupLanguage(),
        _setupCurrency(),
        _setupGoogleAPIKey(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          log('⏱️ Initialization timed out');
          return [];
        },
      );
    } catch (e, s) {
      log('❌ Initialization error: $e\n$s');
    } finally {
      log('✅ Initialization complete');
      isLoading.value = false;

      // Initialize notifications AFTER loading is done
      _initializeNotifications();
    }
  }

  Future<void> _setupLanguage() async {
    try {
      log('🌍 Setting up language...');

      // Just save language, don't try to change locale
      if (Preferences.getString(Preferences.languageCodeKey).isNotEmpty) {
        log('ℹ️ Language already configured');
        return;
      }

      final languages = await FireStoreUtils.getLanguage().timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );

      if (languages != null && languages.isNotEmpty) {
        LanguageModel languageModel;
        try {
          languageModel = languages.firstWhere((e) => e.isDefault == true);
        } catch (_) {
          languageModel = languages.first;
        }

        Preferences.setString(
          Preferences.languageCodeKey,
          jsonEncode(languageModel),
        );
        log('✅ Language saved: ${languageModel.code}');
      }
    } catch (e) {
      log('⚠️ Language setup failed: $e');
    }
  }

  Future<void> _setupCurrency() async {
    try {
      log('💰 Setting up currency...');

      final currency = await FireStoreUtils().getCurrency().timeout(
            const Duration(seconds: 3),
            onTimeout: () => null,
          );

      Constant.currencyModel = currency ??
          CurrencyModel(
            id: "",
            code: "USD",
            decimalDigits: 2,
            enable: true,
            name: "US Dollar",
            symbol: "\$",
            symbolAtRight: false,
          );

      log('✅ Currency set: ${Constant.currencyModel?.code}');
    } catch (e) {
      log('⚠️ Currency setup failed: $e');
    }
  }

  Future<void> _setupGoogleAPIKey() async {
    try {
      log('🔑 Getting Google API key...');

      await FireStoreUtils().getGoogleAPIKey().timeout(
            const Duration(seconds: 3),
            onTimeout: () => log('⏱️ Google API key fetch timed out'),
          );

      log('✅ Google API key retrieved');
    } catch (e) {
      log('⚠️ Google API key fetch failed: $e');
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      log('📱 Initializing notifications...');

      await notificationService.initInfo();
      final token = await NotificationService.getToken();
      log("FCM TOKEN: $token");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final driver =
          await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid());

      if (driver == null) return;

      driver.fcmToken = token;
      await FireStoreUtils.updateDriverUser(driver);
      log('✅ Notifications initialized');
    } catch (e) {
      log('⚠️ Notification init failed: $e');
    }
  }
}
