import 'package:driver/lang/app_ar.dart';
import 'package:driver/lang/app_en.dart';
import 'package:driver/lang/app_fr.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer';

class LocalizationService extends Translations {
  // Default locale
  static const locale = Locale('en', 'US');

  static final locales = [
    const Locale('en'),
    const Locale('ar'),
    const Locale('fr'),
  ];

  @override
  Map<String, Map<String, String>> get keys => {
        'en': enUS,
        'ar': arAR,
        'fr': trFr,
      };

  // SAFE locale change - uses Future.delayed to ensure Navigator is ready
  void changeLocale(String lang) {
    log('🌍 Attempting to change locale to: $lang');

    // Wait longer and check if context is available
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        if (Get.context != null) {
          Get.updateLocale(Locale(lang));
          log('✅ Locale changed to: $lang');
        } else {
          log('⚠️ Get.context is null, cannot change locale');
        }
      } catch (e) {
        log('❌ Error changing locale: $e');
      }
    });
  }
}
