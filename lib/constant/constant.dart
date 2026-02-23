// ignore_for_file: deprecated_member_use, non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:driver/constant/env.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/admin_commission.dart';
import 'package:driver/model/conversation_model.dart';
import 'package:driver/model/currency_model.dart';
import 'package:driver/model/language_description.dart';
import 'package:driver/model/language_model.dart';
import 'package:driver/model/language_name.dart';
import 'package:driver/model/language_privacy_policy.dart';
import 'package:driver/model/language_terms_condition.dart';
import 'package:driver/model/language_title.dart';
import 'package:driver/model/map_model.dart';
import 'package:driver/model/order/location_lat_lng.dart';
import 'package:driver/model/tax_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/preferences.dart';
import 'package:driver/utils/app_logger.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class Constant {
  static const String DUMMY_PHONE_NUMBER = "9999999999";
  static const String DUMMY_COUNTRY_CODE = "+91";
  static const String DUMMY_OTP = "123456";
  static const String DUMMY_SESSION_ID = "TEST_SESSION_123";
  static const String DUMMY_DRIVER_ID = "TEST_DRIVER_123";
  static const bool ENABLE_DUMMY_AUTH = true;

  static const String appName = 'Spelcabs';
  static const String appPackageName = 'com.bidbolt.driver';

  static const String globalUrl = "https://bidbolt.socialspark.world/";

  // Throttling Constants (for Adaptive Location Tracking)
  static const int firestoreWriteThrottleMs = 30000; // 30 seconds (Idle)
  static const int firestoreWriteActiveThrottleMs =
      5000; // 5 seconds (Active Ride)

  static const int locationIdleInterval = 15000; // 15 seconds
  static const double locationIdleDistanceFilter = 50.0; // 50 meters
  static const int locationActiveInterval = 5000; // 5 seconds
  static const double locationActiveDistanceFilter = 20.0; // 20 meters

  // Radius Parsing
  static double getParsedRadius() {
    final parsed = double.tryParse(radius) ?? 100.0;
    if (parsed > 300.0) {
      return parsed / 1000.0;
    } else if (parsed > 0) {
      return parsed;
    } else {
      return 100.0;
    }
  }

  // URLs
  static const String phonepeCallbackUrl =
      '${globalUrl}payment/phonepe_callback';
  static const String phonepeRedirectUrl =
      '${globalUrl}payment/phonepe_redirect';
  static const String phonepeFailureUrl = '${globalUrl}payment/phonepe_failure';

  static const String googleMapKey = 'YOUR_GOOGLE_MAP_API_KEY_HERE';
  static const String serverKey = 'YOUR_FIREBASE_SERVER_KEY_HERE';

  static const String isGuestModeKey = "isGuestMode";
  static Color get = AppColors.primary;

  static const String phoneLoginType = "phone";
  static const String googleLoginType = "google";
  static const String appleLoginType = "apple";
  static LocationLatLng? currentLocation;

  static String mapAPIKey = Env.mapAPIKey;
  static String senderId = 'bidbolt-5d325';
  static String jsonNotificationFileURL =
      'https://firebasestorage.googleapis.com/v0/b/bidbolt-5d325.firebasestorage.app/o/bidbolt-5d325-firebase-adminsdk-fbsvc-f30b7cc63d.json?alt=media&token=aed7260b-4e6a-467c-9e4e-81be5759188d';
  static String radius = "100";
  static String distanceType = "";
  static String minimumAmountToWithdrawal = "0.0";
  static String minimumDepositToRideAccept = "0.0";
  static List<LanguageTermsCondition> termsAndConditions = [];
  static List<LanguagePrivacyPolicy> privacyPolicy = [];
  static String? supportURL = "";
  static String appVersion = "";
  static bool isVerifyDocument = false;

  static String mapType = "google";
  static String selectedMapType = 'google';

  static String driverLocationUpdate = "10";

  static CurrencyModel? currencyModel;
  static List<TaxModel>? taxList;

  static const String ridePlaced = "Ride Placed";
  static const String rideActive = "Ride Active";
  static const String rideInProgress = "Ride InProgress";
  static const String rideComplete = "Ride Completed";
  static const String rideCanceled = "Ride Canceled";

  static String? referralAmount = "0";
  static const String freightServiceId = "Kn2VEnPI3ikF58uK8YqY";

  static const List<String> worldwideZoneKeywords = [
    'worldwide',
    'world wide',
    'global',
    'international',
    'all cities',
    'all zones',
  ];

  static bool isWorldwideZone(String? zoneName) {
    if (zoneName == null || zoneName.trim().isEmpty) return false;
    final lowerName = zoneName.toLowerCase().trim();
    return worldwideZoneKeywords.any((keyword) => lowerName.contains(keyword));
  }

  static bool hasWorldwideZone(List<String>? zoneNames) {
    if (zoneNames == null || zoneNames.isEmpty) return false;
    return zoneNames.any((name) => isWorldwideZone(name));
  }

  static const String cityRideWorldwideValidationMessage =
      "City rides are available only within a single city. Please select a valid city pickup and drop.";
  static const String cityRideOutsideBoundaryMessage =
      "City rides are available only within city limits";
  static const String pickupDropSameZoneMessage =
      "Pickup and drop must be within the same city zone for city rides";

  static const userPlaceHolder =
      "https://firebasestorage.googleapis.com/v0/b/goride-1a752.appspot.com/o/placeholderImages%2Fuser-placeholder.jpeg?alt=media&token=34a73d67-ba1d-4fe4-a29f-271d3e3ca115";

  static const String twoFactorBaseUrl = 'https://2factor.in/API/V1';
  static const String twoFactorApiKey = "1d81aa81-e83a-11ee-8cbb-0200cd936042";

  static const String driverUserModelKey = "driverUserModelKey";
  static const String isLoggedInKey = "isLoggedInKey";
  static const String driverIdKey = "driverIdKey";
  static const String driverNameKey = "driverNameKey";
  static const String driverEmailKey = "driverEmailKey";
  static const String driverPhoneKey = "driverPhoneKey";
  static const String driverImageKey = "driverImageKey";

  static var razorPayKey;
  static var adminCommission;

  static Widget loader(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.darkModePrimary),
    );
  }

  static bool isGuestMode() {
    return Preferences.getBoolean(isGuestModeKey);
  }

  static String localizationName(List<LanguageName>? name) {
    if (name == null || name.isEmpty) return "";
    try {
      final currentLangCode = Constant.getLanguage().code;
      final currentMatch = name.firstWhere(
          (e) => e.type == currentLangCode && (e.name?.isNotEmpty ?? false));
      return currentMatch.name!;
    } catch (_) {
      try {
        final englishMatch = name
            .firstWhere((e) => e.type == "en" && (e.name?.isNotEmpty ?? false));
        return englishMatch.name!;
      } catch (_) {
        for (var item in name) {
          if (item.name?.isNotEmpty ?? false) return item.name!;
        }
      }
    }
    return "";
  }

  static String localizationTitle(List<LanguageTitle>? name) {
    try {
      return name!
          .firstWhere((element) =>
              element.type == Constant.getLanguage().code &&
              (element.title?.isNotEmpty ?? false))
          .title!;
    } catch (_) {
      try {
        return name!.firstWhere((element) => element.type == "en").title!;
      } catch (e) {
        return name!.first.title ?? "";
      }
    }
  }

  static String localizationDescription(List<LanguageDescription>? name) {
    try {
      return name!
          .firstWhere((element) =>
              element.type == Constant.getLanguage().code &&
              (element.description?.isNotEmpty ?? false))
          .description!;
    } catch (_) {
      try {
        return name!.firstWhere((element) => element.type == "en").description!;
      } catch (e) {
        return name!.first.description ?? "";
      }
    }
  }

  static Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  static String localizationPrivacyPolicy(List<LanguagePrivacyPolicy>? name) {
    try {
      return name!
          .firstWhere((element) =>
              element.type == Constant.getLanguage().code &&
              (element.privacyPolicy?.isNotEmpty ?? false))
          .privacyPolicy!;
    } catch (_) {
      try {
        return name!
            .firstWhere((element) => element.type == "en")
            .privacyPolicy!;
      } catch (e) {
        return name!.first.privacyPolicy ?? "";
      }
    }
  }

  static String localizationTermsCondition(List<LanguageTermsCondition>? name) {
    try {
      return name!
          .firstWhere((element) =>
              element.type == Constant.getLanguage().code &&
              (element.termsAndConditions?.isNotEmpty ?? false))
          .termsAndConditions!;
    } catch (_) {
      try {
        return name!
            .firstWhere((element) => element.type == "en")
            .termsAndConditions!;
      } catch (e) {
        return name!.first.termsAndConditions ?? "";
      }
    }
  }

  static Future<MapModel?> getDurationDistance(
      LatLng departureLatLong, LatLng destinationLatLong) async {
    String url = 'https://maps.googleapis.com/maps/api/distancematrix/json';
    http.Response restaurantToCustomerTime = await http.get(Uri.parse(
        '$url?units=metric&origins=${departureLatLong.latitude},'
        '${departureLatLong.longitude}&destinations=${destinationLatLong.latitude},${destinationLatLong.longitude}&key=${Constant.mapAPIKey}'));
    MapModel mapModel =
        MapModel.fromJson(jsonDecode(restaurantToCustomerTime.body));

    if (mapModel.status == 'OK' &&
        mapModel.rows!.first.elements!.first.status == "OK") {
      return mapModel;
    } else {
      ShowToastDialog.showToast(mapModel.errorMessage);
    }
    return null;
  }

  static double amountCalculate(String amount, String distance) {
    try {
      final double amountValue = double.tryParse(amount) ?? 0.0;
      final double distanceValue = double.tryParse(distance) ?? 0.0;
      return amountValue * distanceValue;
    } catch (e) {
      AppLogger.error('Error calculating amount: $e', tag: 'Constant');
      return 0.0;
    }
  }

  static bool? validateEmail(String? value) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(value ?? '');
  }

  static Future<String> uploadUserImageToFireStorage(
      File image, String filePath, String fileName) async {
    Reference upload =
        FirebaseStorage.instance.ref().child('$filePath/$fileName');
    UploadTask uploadTask = upload.putFile(image);
    var downloadUrl =
        await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
    return downloadUrl.toString();
  }

  bool hasValidUrl(String value) {
    String pattern =
        r'(http|https)://[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:/~+#-]*[\w@?^=%&amp;/~+#-])?';
    RegExp regExp = RegExp(pattern);
    return value.isNotEmpty && regExp.hasMatch(value);
  }

  static Future<DateTime?> selectFetureDate(BuildContext context) async {
    final themeChange = Provider.of<DarkThemeProvider>(context, listen: false);
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
      builder: (context, child) {
        return Theme(
          data: themeChange.getThem()
              ? ThemeData.dark().copyWith(
                  primaryColor: Colors.white,
                  colorScheme: const ColorScheme.dark(
                      primary: Colors.white,
                      onPrimary: Colors.black,
                      onSurface: Colors.white),
                  buttonTheme:
                      const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                  dialogBackgroundColor: AppColors.darkBackground,
                )
              : ThemeData.light().copyWith(
                  primaryColor: AppColors.primary,
                  colorScheme:
                      const ColorScheme.light(primary: AppColors.primary),
                  buttonTheme:
                      const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                ),
          child: child!,
        );
      },
    );
    return pickedDate;
  }

  static Future<DateTime?> selectDate(BuildContext context) async {
    final themeChange = Provider.of<DarkThemeProvider>(context, listen: false);
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: themeChange.getThem()
              ? ThemeData.dark().copyWith(
                  primaryColor: Colors.white,
                  colorScheme: const ColorScheme.dark(
                      primary: Colors.white,
                      onPrimary: Colors.black,
                      onSurface: Colors.white),
                  buttonTheme:
                      const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                  dialogBackgroundColor: AppColors.darkBackground,
                )
              : ThemeData.light().copyWith(
                  primaryColor: AppColors.primary,
                  colorScheme:
                      const ColorScheme.light(primary: AppColors.primary),
                  buttonTheme:
                      const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                ),
          child: child!,
        );
      },
    );
    return pickedDate;
  }

  static double parseDurationStringToMinutes(String durationString) {
    double totalMinutes = 0.0;
    String normalizedString = durationString
        .toLowerCase()
        .replaceAll('minutes', 'minute')
        .replaceAll('hours', 'hour');
    final parts = normalizedString.split(' ');
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].contains('hour')) {
        if (i > 0) totalMinutes += (double.tryParse(parts[i - 1]) ?? 0) * 60;
      } else if (parts[i].contains('minute') || parts[i].contains('mins')) {
        if (i > 0) totalMinutes += double.tryParse(parts[i - 1]) ?? 0;
      }
    }
    return totalMinutes;
  }

  double calculateTax({String? amount, TaxModel? taxModel}) {
    double taxAmount = 0.0;
    if (taxModel != null && taxModel.enable == true) {
      if (taxModel.type == "fix") {
        taxAmount = double.parse(taxModel.tax.toString());
      } else {
        taxAmount = (double.parse(amount.toString()) *
                double.parse(taxModel.tax!.toString())) /
            100;
      }
    }
    return taxAmount;
  }

  static double calculateAdminCommission(
      {String? amount, AdminCommission? adminCommission}) {
    double taxAmount = 0.0;
    if (adminCommission != null) {
      if (adminCommission.type == "fix") {
        taxAmount = double.parse(adminCommission.amount.toString());
      } else {
        taxAmount = (double.parse(amount.toString()) *
                double.parse(adminCommission.amount!.toString())) /
            100;
      }
    }
    return taxAmount;
  }

  String formatTimestamp(Timestamp? timestamp) {
    final DateTime dt = timestamp!.toDate().toLocal();
    try {
      final String locale =
          (Constant.getLanguage().code ?? Intl.getCurrentLocale());
      final format = DateFormat('dd-MM-yyyy hh:mm a', locale);
      return format.format(dt);
    } catch (_) {
      String two(int n) => n.toString().padLeft(2, '0');
      int hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      return '${two(dt.day)}-${two(dt.month)}-${dt.year} ${two(hour)}:${two(dt.minute)} ${dt.hour >= 12 ? 'PM' : 'AM'}';
    }
  }

  static String getUuid() {
    return const Uuid().v4();
  }

  static String dateFormatTimestamp(Timestamp? timestamp) {
    final DateTime dt = timestamp!.toDate().toLocal();
    try {
      final String locale =
          (Constant.getLanguage().code ?? Intl.getCurrentLocale());
      return DateFormat('dd MMM yyyy', locale).format(dt);
    } catch (_) {
      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    }
  }

  static String dateAndTimeFormatTimestamp(Timestamp? timestamp) {
    final DateTime dt = timestamp!.toDate().toLocal();
    try {
      final String locale =
          (Constant.getLanguage().code ?? Intl.getCurrentLocale());
      return DateFormat('dd MMM yyyy hh:mm a', locale).format(dt);
    } catch (_) {
      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ];
      int hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year} ${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
    }
  }

  static DateTime parseTimeString(String timeString) {
    timeString = timeString.trim();
    try {
      return DateFormat('hh:mm a').parse(timeString);
    } catch (_) {
      try {
        return DateFormat('HH:mm').parse(timeString);
      } catch (e) {
        final RegExp twelveHour = RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$');
        final match12 = twelveHour.firstMatch(timeString);
        if (match12 != null) {
          int hour = int.parse(match12.group(1)!);
          int minute = int.parse(match12.group(2)!);
          final ampm = match12.group(3)!.toLowerCase();
          if (ampm == 'am' && hour == 12) hour = 0;
          if (ampm == 'pm' && hour != 12) hour += 12;
          final now = DateTime.now();
          return DateTime(now.year, now.month, now.day, hour, minute);
        }
        return DateTime.parse(timeString);
      }
    }
  }

  static bool IsNegative(double number) {
    return number.isNegative;
  }

  static String calculateReview(
      {required String? reviewCount, required String? reviewSum}) {
    if (reviewCount == "0.0" && reviewSum == "0.0") return "0.0";
    return (double.parse(reviewSum.toString()) /
            double.parse(reviewCount.toString()))
        .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
  }

  static String amountShow({required String? amount}) {
    if (Constant.currencyModel!.symbolAtRight == true) {
      return "${double.parse(amount.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!)} ${Constant.currencyModel!.symbol.toString()}";
    } else {
      return "${Constant.currencyModel!.symbol.toString()} ${double.parse(amount.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!)}";
    }
  }

  static LanguageModel getLanguage() {
    try {
      final String user = Preferences.getString(Preferences.languageCodeKey);
      if (user.trim().isEmpty) return LanguageModel.defaultLanguage();
      final decoded = jsonDecode(user);
      if (decoded is Map<String, dynamic>)
        return LanguageModel.fromJson(decoded);
      return LanguageModel.defaultLanguage();
    } catch (e) {
      return LanguageModel.defaultLanguage();
    }
  }

  Future<Url> uploadChatImageToFireStorage(File image) async {
    ShowToastDialog.showLoader('Uploading image...');
    var uniqueID = const Uuid().v4();
    Reference upload =
        FirebaseStorage.instance.ref().child('/chat/images/$uniqueID.png');
    UploadTask uploadTask = upload.putFile(image);
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    ShowToastDialog.closeLoader();
    return Url(
        mime: metaData.contentType ?? 'image', url: downloadUrl.toString());
  }

  Future<String> uploadVideoThumbnailToFireStorage(File file) async {
    var uniqueID = const Uuid().v4();
    Reference upload =
        FirebaseStorage.instance.ref().child('/thumbnails/$uniqueID.png');
    UploadTask uploadTask = upload.putFile(file);
    return await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }
}
