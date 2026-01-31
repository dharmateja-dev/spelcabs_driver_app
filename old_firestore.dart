import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/bank_details_model.dart';
import 'package:driver/model/conversation_model.dart';
import 'package:driver/model/currency_model.dart';
import 'package:driver/model/document_model.dart';
import 'package:driver/model/driver_document_model.dart';
import 'package:driver/model/driver_rules_model.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/inbox_model.dart';
import 'package:driver/model/intercity_order_model.dart';
import 'package:driver/model/language_model.dart';
import 'package:driver/model/language_privacy_policy.dart';
import 'package:driver/model/language_terms_condition.dart';
import 'package:driver/model/on_boarding_model.dart';
import 'package:driver/model/order/driverId_accept_reject.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/payment_model.dart';
import 'package:driver/model/referral_model.dart';
import 'package:driver/model/review_model.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/subscription_plan_model.dart';
import 'package:driver/model/subscription_history.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/model/vehicle_type_model.dart';
import 'package:driver/model/wallet_transaction_model.dart';
import 'package:driver/model/withdraw_model.dart';
import 'package:driver/model/zone_model.dart';
import 'package:driver/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:driver/widget/geoflutterfire/src/models/point.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:driver/utils/app_logger.dart';
import 'package:driver/utils/Preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FireStoreUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  static FirebaseMessaging get = FirebaseMessaging.instance;

  static DriverUserModel? currentDriverUser;

  static const String _driverUsersCollection = 'driver_users';

  static Future<bool> updateDriverUser(DriverUserModel driverUserModel) async {
    AppLogger.debug("updateDriverUser called for ID: ${driverUserModel.id}",
        tag: "FireStoreUtils");
    try {
      await fireStore
          .collection(_driverUsersCollection)
          .doc(driverUserModel.id) // Use the driver's ID as the document ID
          .set(driverUserModel.toJson(), SetOptions(merge: true));
      AppLogger.info(
          "FireStoreUtils: Driver user updated/created successfully for ID: ${driverUserModel.id}",
          tag: "FireStoreUtils");
      return true;
    } catch (e, s) {
      AppLogger.error("FireStoreUtils: Error updating/creating driver user",
          tag: "FireStoreUtils", error: e, stackTrace: s);
      ShowToastDialog.showToast("Failed to save user data. Please try again.");
      return false;
    }
  }

  /// Retrieves a driver user profile from Firestore by their Firebase Auth UID.
  /// This is primarily for users who signed in via Google/Apple.
  static Future<DriverUserModel?> getDriverProfile(String uid) async {
    AppLogger.debug("getDriverProfile called for UID: $uid",
        tag: "FireStoreUtils");
    try {
      final docSnapshot =
          await fireStore.collection(_driverUsersCollection).doc(uid).get();
      if (docSnapshot.exists) {
        AppLogger.info(
            "FireStoreUtils: Driver profile retrieved successfully for UID: $uid",
            tag: "FireStoreUtils");
        return DriverUserModel.fromJson(docSnapshot.data()!);
      } else {
        AppLogger.warning(
            "FireStoreUtils: No driver profile found for UID: $uid",
            tag: "FireStoreUtils");
        return null;
      }
    } catch (e, s) {
      AppLogger.error("FireStoreUtils: Error getting driver profile by UID",
          tag: "FireStoreUtils", error: e, stackTrace: s);
      return null;
    }
  }

  /// Retrieves a driver user profile from Firestore by their phone number.
  /// This is primarily for users who signed in via phone (2Factor).
  static Future<DriverUserModel?> getDriverProfileByPhoneNumber(
      String countryCode, String localPhoneNumber) async {
    AppLogger.debug(
        "getDriverProfileByPhoneNumber called for phone: $countryCode$localPhoneNumber",
        tag: "FireStoreUtils");
    try {
      final querySnapshot = await fireStore
          .collection(_driverUsersCollection)
          .where('countryCode', isEqualTo: countryCode)
          .where('phoneNumber', isEqualTo: localPhoneNumber)
          .limit(1) // Assuming countryCode + phoneNumber is unique
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        AppLogger.info(
            "FireStoreUtils: Driver profile retrieved successfully for phone number: $countryCode$localPhoneNumber",
            tag: "FireStoreUtils");
        return DriverUserModel.fromJson(querySnapshot.docs.first.data());
      } else {
        AppLogger.warning(
            "FireStoreUtils: No driver profile found for phone number: $countryCode$localPhoneNumber",
            tag: "FireStoreUtils");
        return null;
      }
    } catch (e, s) {
      AppLogger.error(
          "FireStoreUtils: Error getting driver profile by phone number",
          tag: "FireStoreUtils",
          error: e,
          stackTrace: s);
      return null;
    }
  }

  /// Retrieves a driver user profile from Firestore by their email address.
  /// Returns null if not found.
  static Future<DriverUserModel?> getDriverProfileByEmail(String email) async {
    AppLogger.debug("getDriverProfileByEmail called for email: $email",
        tag: "FireStoreUtils");
    try {
      // Try exact match first
      var querySnapshot = await fireStore
          .collection(_driverUsersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      // If not found, try lower-case match (for entries saved with lower-case)
      if (querySnapshot.docs.isEmpty) {
        final lower = email.toLowerCase();
        querySnapshot = await fireStore
            .collection(_driverUsersCollection)
            .where('email', isEqualTo: lower)
            .limit(1)
            .get();
      }

      if (querySnapshot.docs.isNotEmpty) {
        AppLogger.info(
            "FireStoreUtils: Driver profile retrieved successfully for email: $email",
            tag: "FireStoreUtils");
        return DriverUserModel.fromJson(querySnapshot.docs.first.data());
      } else {
        AppLogger.info(
            "FireStoreUtils: No driver profile found for email: $email",
            tag: "FireStoreUtils");
        return null;
      }
    } catch (e, s) {
      AppLogger.error("FireStoreUtils: Error getting driver profile by email",
          tag: "FireStoreUtils", error: e, stackTrace: s);
      return null;
    }
  }

  /// Check if email/phone exists in both users (customer) and driver_users collections
  static Future<bool> isEmailOrPhoneRegistered(
      String email, String? countryCode, String? phoneNumber) async {
    try {
      // Check in driver_users collection
      if (email.isNotEmpty) {
        final driverEmail = await fireStore
            .collection(_driverUsersCollection)
            .where('email', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();
        if (driverEmail.docs.isNotEmpty) {
          AppLogger.debug('Email exists in driver_users collection: $email',
              tag: 'FireStoreUtils');
          return true;
        }
      }

      // Check in users (customer) collection
      if (email.isNotEmpty) {
        final userEmail = await fireStore
            .collection('users')
            .where('email', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();
        if (userEmail.docs.isNotEmpty) {
          AppLogger.debug('Email exists in users collection: $email',
              tag: 'FireStoreUtils');
          return true;
        }
      }

      // Check phone in driver_users
      if (phoneNumber != null &&
          phoneNumber.isNotEmpty &&
          countryCode != null) {
        final driverPhone = await fireStore
            .collection(_driverUsersCollection)
            .where('countryCode', isEqualTo: countryCode)
            .where('phoneNumber', isEqualTo: phoneNumber)
            .limit(1)
            .get();
        if (driverPhone.docs.isNotEmpty) {
          AppLogger.debug(
              'Phone exists in driver_users collection: $countryCode$phoneNumber',
              tag: 'FireStoreUtils');
          return true;
        }
      }

      // Check phone in users (customer) collection
      if (phoneNumber != null &&
          phoneNumber.isNotEmpty &&
          countryCode != null) {
        final userPhone = await fireStore
            .collection('users')
            .where('countryCode', isEqualTo: countryCode)
            .where('phoneNumber', isEqualTo: phoneNumber)
            .limit(1)
            .get();
        if (userPhone.docs.isNotEmpty) {
          AppLogger.debug(
              'Phone exists in users collection: $countryCode$phoneNumber',
              tag: 'FireStoreUtils');
          return true;
        }
      }

      return false;
    } catch (e, s) {
      AppLogger.error('Error checking email/phone registration',
          tag: 'FireStoreUtils', error: e, stackTrace: s);
      return false;
    }
  }

  /// Checks if a user is logged in.
  /// This method now checks both local preferences (for phone users) and Firebase Auth (for social users).
  static Future<bool> isLogin() async {
    AppLogger.debug("isLogin called.", tag: "FireStoreUtils");
    // Check local preferences first for phone users
    bool isLoggedInLocally = Preferences.getBoolean(Constant.isLoggedInKey);
    if (isLoggedInLocally) {
      String? driverId = Preferences.getString(Constant.driverIdKey);
      if (driverId != null && driverId.isNotEmpty) {
        // Attempt to fetch profile from Firestore to ensure data consistency
        DriverUserModel? driverModel = await getDriverProfile(driverId);
        if (driverModel != null) {
          currentDriverUser = driverModel;
          AppLogger.info(
              "FireStoreUtils: User logged in via local preferences and Firestore data confirmed.",
              tag: "FireStoreUtils");
          return true;
        } else {
          // Inconsistent state: local flag true, but no Firestore data. Clear local and return false.
          AppLogger.warning(
              "FireStoreUtils: Inconsistent local login state detected. Clearing preferences.",
              tag: "FireStoreUtils");
          await Preferences.clearDriverUserData();
          await Preferences.setBoolean(Constant.isLoggedInKey, false);
          currentDriverUser = null;
          return false;
        }
      }
    }

    // If not logged in locally, check Firebase Auth for social logins
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      // User is authenticated with Firebase Auth (e.g., Google, Apple)
      DriverUserModel? driverModel = await getDriverProfile(firebaseUser.uid);
      if (driverModel != null) {
        currentDriverUser = driverModel;
        // Also save to local preferences for consistency, especially for social logins
        await Preferences.saveDriverUserData(driverModel);
        await Preferences.setBoolean(Constant.isLoggedInKey, true);
        AppLogger.info(
            "FireStoreUtils: User logged in via Firebase Auth and Firestore data confirmed.",
            tag: "FireStoreUtils");
        return true;
      } else {
        // User authenticated with Firebase, but no profile in Firestore.
        // This might indicate an incomplete social signup.
        AppLogger.warning(
            "FireStoreUtils: Firebase Auth user found, but no Firestore profile. Likely incomplete signup.",
            tag: "FireStoreUtils");
        // Do not clear Firebase Auth session, but indicate not fully logged in for app purposes
        currentDriverUser = null;
        return false;
      }
    }

    AppLogger.info("FireStoreUtils: User is not logged in.",
        tag: "FireStoreUtils");
    currentDriverUser = null;
    return false;
  }

  /// Gets the current user's UID.
  /// For phone users, it gets from preferences. For social users, from Firebase Auth.
  static String getCurrentUid() {
    String? uidFromPrefs = Preferences.getString(Constant.driverIdKey);
    User? firebaseUser = FirebaseAuth.instance.currentUser;

    if (uidFromPrefs != null && uidFromPrefs.isNotEmpty) {
      AppLogger.debug(
          "getCurrentUid: Returning UID from preferences: $uidFromPrefs",
          tag: "FireStoreUtils");
      return uidFromPrefs;
    } else if (firebaseUser != null) {
      AppLogger.debug(
          "getCurrentUid: Returning UID from Firebase Auth: ${firebaseUser.uid}",
          tag: "FireStoreUtils");
      return firebaseUser.uid;
    } else {
      AppLogger.warning(
          "FireStoreUtils: No current UID found from preferences or Firebase Auth.",
          tag: "FireStoreUtils");
      return ''; // Or throw an error, depending on desired behavior
    }
  }

  /// Signs out the current user from Firebase Auth and clears local preferences.
  static Future<void> logout() async {
    AppLogger.debug("logout called.", tag: "FireStoreUtils");
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut(); // Also sign out from Google if signed in
      await Preferences.clearDriverUserData();
      await Preferences.setBoolean(Constant.isLoggedInKey, false);
      currentDriverUser = null;
      AppLogger.info("FireStoreUtils: User logged out successfully.",
          tag: "FireStoreUtils");
      ShowToastDialog.showToast("Logged out successfully.");
    } catch (e, s) {
      AppLogger.error("FireStoreUtils: Error during logout",
          tag: "FireStoreUtils", error: e, stackTrace: s);
      ShowToastDialog.showToast("Failed to log out: $e");
    }
  }

  static Future<DriverUserModel?> getCurrentDriverUser() async {
    AppLogger.debug("getCurrentDriverUser called.", tag: "FireStoreUtils");
    // 1. Try to get from the static variable
    if (currentDriverUser != null) {
      AppLogger.debug(
          "FireStoreUtils: Returning currentDriverUser from static variable.",
          tag: "FireStoreUtils");
      return currentDriverUser;
    }

    // 2. Try to get from SharedPreferences
    DriverUserModel? userFromPrefs = Preferences.getDriverUserData();
    if (userFromPrefs != null) {
      currentDriverUser = userFromPrefs; // Set static variable
      AppLogger.debug(
          "FireStoreUtils: Returning currentDriverUser from SharedPreferences.",
          tag: "FireStoreUtils");
      return currentDriverUser;
    }

    // 3. If not in prefs, check Firebase Auth and then fetch from Firestore
    //    Note: This part might be less relevant for phone/social logins handled by custom backend.
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        DocumentSnapshot documentSnapshot = await fireStore
            .collection(
                "driverUsers") // Assuming "driverUsers" is the collection name for drivers
            .doc(firebaseUser.uid)
            .get();
        if (documentSnapshot.exists) {
          DriverUserModel user = DriverUserModel.fromJson(
              documentSnapshot.data() as Map<String, dynamic>);
          currentDriverUser = user; // Set static variable
          await Preferences.saveDriverUserData(
              user); // Save to preferences for next time
          AppLogger.info(
              "FireStoreUtils: Fetched currentDriverUser from Firestore and saved to preferences.",
              tag: "FireStoreUtils");
          return currentDriverUser;
        } else {
          AppLogger.warning(
              "FireStoreUtils: Firebase user found, but no matching document in Firestore for UID: ${firebaseUser.uid}",
              tag: "FireStoreUtils");
          await Preferences
              .clearDriverUserData(); // Clear potentially stale login info
          await FirebaseAuth.instance.signOut();
          return null;
        }
      } catch (e, s) {
        AppLogger.error(
            "FireStoreUtils: Error fetching driver from Firestore for UID: ${firebaseUser.uid}",
            tag: "FireStoreUtils",
            error: e,
            stackTrace: s);
        await Preferences.clearDriverUserData();
        await FirebaseAuth.instance.signOut();
        return null;
      }
    }

    AppLogger.info(
        "FireStoreUtils: No current driver user found via Firebase Auth or Preferences.",
        tag: "FireStoreUtils");
    return null;
  }

  getGoogleAPIKey() async {
    AppLogger.debug("getGoogleAPIKey called.", tag: "FireStoreUtils");
    await fireStore
        .collection(CollectionName.settings)
        .doc("globalKey")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.mapAPIKey = value.data()!["googleMapKey"];
        AppLogger.info("Google Map API Key loaded.", tag: "FireStoreUtils");
      } else {
        AppLogger.warning("GlobalKey document not found in settings.",
            tag: "FireStoreUtils");
      }
    }).catchError((error) {
      AppLogger.error("Error loading Google Map API Key: $error",
          tag: "FireStoreUtils", error: error);
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("notification_setting")
        .get()
        .then((value) {
      if (value.exists) {
        if (value.data() != null) {
          Constant.senderId = value.data()!['senderId'].toString();
          Constant.jsonNotificationFileURL =
              value.data()!['serviceJson'].toString();
          AppLogger.info("Notification settings loaded.",
              tag: "FireStoreUtils");
        }
      } else {
        AppLogger.warning(
            "Notification_setting document not found in settings.",
            tag: "FireStoreUtils");
      }
    }).catchError((error) {
      AppLogger.error("Error loading notification settings: $error",
          tag: "FireStoreUtils", error: error);
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("globalValue")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.distanceType = value.data()!["distanceType"];
        Constant.radius = value.data()!["radius"];
        Constant.minimumAmountToWithdrawal =
            value.data()!["minimumAmountToWithdrawal"];
        Constant.minimumDepositToRideAccept =
            value.data()!["minimumDepositToRideAccept"];
        Constant.mapType = value.data()!["mapType"];
        Constant.selectedMapType = value.data()!["selectedMapType"];
        Constant.driverLocationUpdate = value.data()!["driverLocationUpdate"];
        Constant.isVerifyDocument = value.data()!["isVerifyDocument"];
        AppLogger.info("Global values loaded.", tag: "FireStoreUtils");
      } else {
        AppLogger.warning("GlobalValue document not found in settings.",
            tag: "FireStoreUtils");
      }
    }).catchError((error) {
      AppLogger.error("Error loading global values: $error",
          tag: "FireStoreUtils", error: error);
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("referral")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.referralAmount = value.data()!["referralAmount"];
        AppLogger.info("Referral amount loaded.", tag: "FireStoreUtils");
      } else {
        AppLogger.warning("Referral document not found in settings.",
            tag: "FireStoreUtils");
      }
    }).catchError((error) {
      AppLogger.error("Error loading referral settings: $error",
          tag: "FireStoreUtils", error: error);
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("global")
        .get()
        .then((value) {
      if (value.exists) {
        if (value.data()!["privacyPolicy"] != null) {
          Constant.privacyPolicy = <LanguagePrivacyPolicy>[];
          value.data()!["privacyPolicy"].forEach((v) {
            Constant.privacyPolicy.add(LanguagePrivacyPolicy.fromJson(v));
          });
        }

        if (value.data()!["termsAndConditions"] != null) {
          Constant.termsAndConditions = <LanguageTermsCondition>[];
          value.data()!["termsAndConditions"].forEach((v) {
            Constant.termsAndConditions.add(LanguageTermsCondition.fromJson(v));
          });
        }
        Constant.appVersion = value.data()!["appVersion"];
        AppLogger.info("Global settings (privacy, terms, app version) loaded.",
            tag: "FireStoreUtils");
      } else {
        AppLogger.warning("Global document not found in settings.",
            tag: "FireStoreUtils");
      }
    }).catchError((error) {
      AppLogger.error("Error loading global settings: $error",
          tag: "FireStoreUtils", error: error);
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("contact_us")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.supportURL = value.data()!["supportURL"];
        AppLogger.info("Contact us URL loaded.", tag: "FireStoreUtils");
      } else {
        AppLogger.warning("Contact_us document not found in settings.",
            tag: "FireStoreUtils");
      }
    }).catchError((error) {
      AppLogger.error("Error loading contact us settings: $error",
          tag: "FireStoreUtils", error: error);
    });
  }

  static Future<bool> checkEmailExists(String email) async {
    AppLogger.debug("checkEmailExists called for email: $email",
        tag: "FireStoreUtils");
    try {
      QuerySnapshot querySnapshot = await fireStore
          .collection(CollectionName.driverUsers)
          .where('email', isEqualTo: email)
          .get();
      AppLogger.info(
          "Email existence check for $email: ${querySnapshot.docs.isNotEmpty}",
          tag: "FireStoreUtils");
      return querySnapshot.docs.isNotEmpty;
    } catch (error, s) {
      AppLogger.error("Error checking email existence: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
      return false;
    }
  }

  static Future<bool> checkPhoneExists(String fullPhoneNumber) async {
    AppLogger.debug("checkPhoneExists called for phone: $fullPhoneNumber",
        tag: "FireStoreUtils");
    try {
      QuerySnapshot querySnapshot = await fireStore
          .collection(CollectionName.driverUsers)
          .where('phoneNumber', isEqualTo: fullPhoneNumber)
          .get();
      AppLogger.info(
          "Phone existence check for $fullPhoneNumber: ${querySnapshot.docs.isNotEmpty}",
          tag: "FireStoreUtils");
      return querySnapshot.docs.isNotEmpty;
    } catch (error, s) {
      AppLogger.error("Error checking phone existence: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
      return false;
    }
  }

  // fire_store_utils.dart
  static Future<UserModel?> getCustomer(String uuid) async {
    AppLogger.debug("getCustomer called for UID: $uuid", tag: "FireStoreUtils");

    if (uuid.isEmpty) {
      AppLogger.warning("Empty UUID passed to getCustomer",
          tag: "FireStoreUtils");
      return null;
    }

    try {
      final document = await fireStore
          .collection(CollectionName.users)
          .doc(uuid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (document.exists) {
        AppLogger.info("User data retrieved for UID: $uuid",
            tag: "FireStoreUtils");
        return UserModel.fromJson(document.data()!);
      }

      AppLogger.warning("User document not found for UID: $uuid",
          tag: "FireStoreUtils");
      return null;
    } catch (e, s) {
      AppLogger.error("Failed to get user $uuid: $e",
          tag: "FireStoreUtils", error: e, stackTrace: s);
      rethrow;
    }
  }
  // static Future<UserModel?> getCustomer(String uuid) async {
  //   AppLogger.debug("getCustomer called for UID: $uuid", tag: "FireStoreUtils");
  //   UserModel? userModel;
  //   await fireStore
  //       .collection(CollectionName.users)
  //       .doc(uuid)
  //       .get()
  //       .then((value) {
  //     if (value.exists) {
  //       userModel = UserModel.fromJson(value.data()!);
  //       AppLogger.info("Customer data retrieved for UID: $uuid", tag: "FireStoreUtils");
  //     } else {
  //       AppLogger.warning("Customer document not found for UID: $uuid", tag: "FireStoreUtils");
  //     }
  //   }).catchError((error, s) {
  //     AppLogger.error("Failed to get customer: $error", tag: "FireStoreUtils", error: error, stackTrace: s);
  //     userModel = null;
  //   });
  //   return userModel;
  // }

  static Future<bool> updateUser(UserModel userModel) async {
    AppLogger.debug("updateUser called for UID: ${userModel.id}",
        tag: "FireStoreUtils");
    bool isUpdate = false;
    await fireStore
        .collection(CollectionName.users)
        .doc(userModel.id)
        .set(userModel.toJson())
        .whenComplete(() {
      isUpdate = true;
      AppLogger.info("User data updated successfully for UID: ${userModel.id}",
          tag: "FireStoreUtils");
    }).catchError((error, s) {
      AppLogger.error("Failed to update user: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
      isUpdate = false;
    });
    return isUpdate;
  }

  Future<PaymentModel?> getPayment() async {
    AppLogger.debug("getPayment called.", tag: "FireStoreUtils");
    print("getPayementFunction has been called.");
    try {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await fireStore
          .collection(CollectionName
              .settings) // Assuming 'setting' is the collection for app settings
          .doc(
              "payment") // Assuming 'paymentSetting' is the document ID for payment configurations
          .get();

      if (documentSnapshot.exists) {
        AppLogger.info("Payment settings retrieved successfully.",
            tag: "FireStoreUtils");
        return PaymentModel.fromJson(documentSnapshot.data()!);
      } else {
        AppLogger.warning("Payment settings document does not exist.",
            tag: "FireStoreUtils");
        // log("Payment settings document does not exist.");
        return null;
      }
    } catch (e, s) {
      AppLogger.error("Error getting payment data: $e",
          tag: "FireStoreUtils", error: e, stackTrace: s);
      // log("Error getting payment data: $e \n$s");
      return null;
    }
  }

  Future<CurrencyModel?> getCurrency() async {
    AppLogger.debug("getCurrency called.", tag: "FireStoreUtils");
    CurrencyModel? currencyModel;
    await fireStore
        .collection(CollectionName.currency)
        .where("enable", isEqualTo: true)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        currencyModel = CurrencyModel.fromJson(value.docs.first.data());
        AppLogger.info("Currency model loaded: ${currencyModel!.code}",
            tag: "FireStoreUtils");
      } else {
        AppLogger.warning("No enabled currency found.", tag: "FireStoreUtils");
      }
    }).catchError((error, s) {
      AppLogger.error("Error getting currency: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    });
    return currencyModel;
  }

  static Future<DriverIdAcceptReject?> getAcceptedOrders(
      String orderId, String driverId) async {
    AppLogger.debug(
        "getAcceptedOrders called for order ID: $orderId, driver ID: $driverId",
        tag: "FireStoreUtils");
    DriverIdAcceptReject? driverIdAcceptReject;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderId)
        .collection("acceptedDriver")
        .doc(driverId)
        .get()
        .then((value) async {
      if (value.exists) {
        driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
        AppLogger.info(
            "Accepted order data retrieved for order ID: $orderId, driver ID: $driverId",
            tag: "FireStoreUtils");
      } else {
        AppLogger.warning(
            "Accepted order document not found for order ID: $orderId, driver ID: $driverId",
            tag: "FireStoreUtils");
      }
    }).catchError((error, s) {
      AppLogger.error("Failed to get accepted order: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
      driverIdAcceptReject = null;
    });
    return driverIdAcceptReject;
  }

  static Future<DriverIdAcceptReject?> getInterCItyAcceptedOrders(
      String orderId, String driverId) async {
    AppLogger.debug(
        "getInterCItyAcceptedOrders called for order ID: $orderId, driver ID: $driverId",
        tag: "FireStoreUtils");
    DriverIdAcceptReject? driverIdAcceptReject;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderId)
        .collection("acceptedDriver")
        .doc(driverId)
        .get()
        .then((value) async {
      if (value.exists) {
        driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
        AppLogger.info(
            "Intercity accepted order data retrieved for order ID: $orderId, driver ID: $driverId",
            tag: "FireStoreUtils");
      } else {
        AppLogger.warning(
            "Intercity accepted order document not found for order ID: $orderId, driver ID: $driverId",
            tag: "FireStoreUtils");
      }
    }).catchError((error, s) {
      AppLogger.error("Failed to get intercity accepted order: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
      driverIdAcceptReject = null;
    });
    return driverIdAcceptReject;
  }

  static Future<bool> userExitOrNot(String uid) async {
    AppLogger.debug("userExitOrNot called for UID: $uid",
        tag: "FireStoreUtils");
    bool isExit = false;

    await fireStore.collection(CollectionName.driverUsers).doc(uid).get().then(
      (value) {
        if (value.exists) {
          isExit = true;
          AppLogger.info("User exists for UID: $uid", tag: "FireStoreUtils");
        } else {
          isExit = false;
          AppLogger.info("User does not exist for UID: $uid",
              tag: "FireStoreUtils");
        }
      },
    ).catchError((error, s) {
      AppLogger.error("Failed to check user existence: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
      isExit = false;
    });
    return isExit;
  }

  static Future<List<DocumentModel>> getDocumentList() async {
    AppLogger.debug("getDocumentList called.", tag: "FireStoreUtils");
    List<DocumentModel> documentList = [];
    await fireStore
        .collection(CollectionName.documents)
        .where('enable', isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .get()
        .then((value) {
      for (var element in value.docs) {
        DocumentModel documentModel = DocumentModel.fromJson(element.data());
        documentList.add(documentModel);
      }
      AppLogger.info("Retrieved ${documentList.length} documents.",
          tag: "FireStoreUtils");
    }).catchError((error, s) {
      AppLogger.error("Error getting document list: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    });
    return documentList;
  }

  static Future<List<ServiceModel>> getService() async {
    AppLogger.debug("getService called.", tag: "FireStoreUtils");
    List<ServiceModel> serviceList = [];
    await fireStore
        .collection(CollectionName.service)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        ServiceModel documentModel = ServiceModel.fromJson(element.data());
        serviceList.add(documentModel);
      }
      AppLogger.info("Retrieved ${serviceList.length} services.",
          tag: "FireStoreUtils");
    }).catchError((error, s) {
      AppLogger.error("Error getting service list: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    });
    return serviceList;
  }

  static Stream<OrderModel?> getOrderByOrderId(String orderId) {
    AppLogger.debug("getOrderByOrderId called for order ID: $orderId",
        tag: "FireStoreUtils");
    // This stream listens to a single document in the 'orders' collection
    // and maps its snapshot to an OrderModel object.
    return fireStore
        .collection(CollectionName.orders)
        .doc(orderId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        // If the document exists and has data, parse it into an OrderModel
        AppLogger.info("Order data stream updated for ID: $orderId",
            tag: "FireStoreUtils");
        return OrderModel.fromJson(snapshot.data()!);
      } else {
        // If the document does not exist or has no data, return null
        AppLogger.warning(
            "Order with ID $orderId does not exist or has no data.",
            tag: "FireStoreUtils");
        print(
            "FireStoreUtils: Order with ID $orderId does not exist or has no data.");
        return null;
      }
    });
  }

  static Future<DriverDocumentModel?> getDocumentOfDriver() async {
    AppLogger.debug(
        "getDocumentOfDriver called for current UID: ${getCurrentUid()}",
        tag: "FireStoreUtils");
    DriverDocumentModel? driverDocumentModel;
    await fireStore
        .collection(CollectionName.driverDocument)
        .doc(getCurrentUid())
        .get()
        .then((value) async {
      if (value.exists) {
        driverDocumentModel = DriverDocumentModel.fromJson(value.data()!);
        AppLogger.info("Driver document retrieved for current UID.",
            tag: "FireStoreUtils");
      } else {
        AppLogger.warning("Driver document not found for current UID.",
            tag: "FireStoreUtils");
      }
    }).catchError((error, s) {
      AppLogger.error("Error getting driver document: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    });
    return driverDocumentModel;
  }

  static Future<bool> uploadDriverDocument(Documents documents) async {
    AppLogger.debug(
        "uploadDriverDocument called for document ID: ${documents.documentId}",
        tag: "FireStoreUtils");
    bool isAdded = false;
    DriverDocumentModel driverDocumentModel = DriverDocumentModel();
    List<Documents> documentsList = [];
    await fireStore
        .collection(CollectionName.driverDocument)
        .doc(getCurrentUid())
        .get()
        .then((value) async {
      if (value.exists) {
        DriverDocumentModel newDriverDocumentModel =
            DriverDocumentModel.fromJson(value.data()!);
        documentsList = newDriverDocumentModel.documents!;
        var contain = newDriverDocumentModel.documents!
            .where((element) => element.documentId == documents.documentId);
        if (contain.isEmpty) {
          documentsList.add(documents);

          driverDocumentModel.id = getCurrentUid();
          driverDocumentModel.documents = documentsList;
          AppLogger.info("New document added to existing driver document.",
              tag: "FireStoreUtils");
        } else {
          var index = newDriverDocumentModel.documents!.indexWhere(
              (element) => element.documentId == documents.documentId);

          driverDocumentModel.id = getCurrentUid();
          documentsList.removeAt(index);
          documentsList.insert(index, documents);
          driverDocumentModel.documents = documentsList;
          isAdded = false;
          ShowToastDialog.showToast("Document is under verification");
          AppLogger.info(
              "Existing document updated and marked for verification.",
              tag: "FireStoreUtils");
        }
      } else {
        documentsList.add(documents);
        driverDocumentModel.id = getCurrentUid();
        driverDocumentModel.documents = documentsList;
        AppLogger.info("New driver document created with first document.",
            tag: "FireStoreUtils");
      }
    }).catchError((error, s) {
      AppLogger.error("Error preparing driver document for upload: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    });

    await fireStore
        .collection(CollectionName.driverDocument)
        .doc(getCurrentUid())
        .set(driverDocumentModel.toJson())
        .then((value) {
      isAdded = true;
      AppLogger.info("Driver document uploaded successfully.",
          tag: "FireStoreUtils");
    }).catchError((error, s) {
      isAdded = false;
      AppLogger.error("Error uploading driver document: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    });

    return isAdded;
  }

  static Future<List<VehicleTypeModel>?> getVehicleType() async {
    AppLogger.debug("getVehicleType called.", tag: "FireStoreUtils");
    List<VehicleTypeModel> vehicleList = [];
    await fireStore
        .collection(CollectionName.vehicleType)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) async {
      for (var element in value.docs) {
        VehicleTypeModel vehicleModel =
            VehicleTypeModel.fromJson(element.data());
        vehicleList.add(vehicleModel);
      }
      AppLogger.info("Retrieved ${vehicleList.length} vehicle types.",
          tag: "FireStoreUtils");
    }).catchError((error, s) {
      AppLogger.error("Error getting vehicle types: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    });
    return vehicleList;
  }

  static Future<List<DriverRulesModel>?> getDriverRules() async {
    AppLogger.debug("getDriverRules called.", tag: "FireStoreUtils");
    List<DriverRulesModel> driverRulesModel = [];
    await fireStore
        .collection(CollectionName.driverRules)
        .where('enable', isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .get()
        .then((value) async {
      for (var element in value.docs) {
        DriverRulesModel vehicleModel =
            DriverRulesModel.fromJson(element.data());
        driverRulesModel.add(vehicleModel);
      }
      AppLogger.info("Retrieved ${driverRulesModel.length} driver rules.",
          tag: "FireStoreUtils");
    }).catchError((error, s) {
      AppLogger.error("Error getting driver rules: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    });
    return driverRulesModel;
  }

  StreamController<List<OrderModel>>? getNearestOrderRequestController;
  // Minimal, drop-in getOrders replacement (imports assumed present)

  // ***************************************************************************************************
  // Stream<List<OrderModel>> getOrders(DriverUserModel driverUserModel,
  //     double? latitude, double? longLatitude) async* {
  //
  //   AppLogger.debug("getOrders called for driver: ${driverUserModel.id}", tag: "FireStoreUtils");
  //   AppLogger.debug("DEBUG center used: ($latitude, $longLatitude), Constant.radius='${Constant.radius}'", tag: "FireStoreUtils");
  //
  //   getNearestOrderRequestController = StreamController<List<OrderModel>>.broadcast();
  //   List<OrderModel> ordersList = [];
  //
  //   // Build base query (zone + status)
  //   Query<Map<String, dynamic>> baseQuery = fireStore
  //       .collection(CollectionName.orders)
  //       .where('zoneId', whereIn: driverUserModel.zoneIds)
  //       .where('status', isEqualTo: Constant.ridePlaced);
  //
  //   // Prefer service-restricted results when possible
  //   Query<Map<String, dynamic>> serviceQuery = baseQuery;
  //   if (driverUserModel.serviceId != null && driverUserModel.serviceId!.isNotEmpty) {
  //     serviceQuery = baseQuery.where('serviceId', isEqualTo: driverUserModel.serviceId);
  //     try {
  //       final snap = await serviceQuery.get();
  //       if (snap.docs.isEmpty) {
  //         AppLogger.debug("No orders for driver's serviceId; falling back to zone-only query.", tag: "FireStoreUtils");
  //         serviceQuery = baseQuery;
  //       }
  //     } catch (e) {
  //       // if raw get fails, continue with serviceQuery ΓÇö Geoflutterfire will handle
  //       AppLogger.debug("Error testing serviceQuery: $e", tag: "FireStoreUtils");
  //     }
  //   }
  //
  //   // Center and radius handling. Accepts radius expressed either in km or meters.
  //   final double centerLat = latitude ?? 0.0;
  //   final double centerLng = longLatitude ?? 0.0;
  //   double radiusKm;
  //   final parsedRadius = double.tryParse(Constant.radius ?? "") ?? 0.0;
  //   // Heuristic: if parsedRadius looks large (>20) treat as meters, else kilometers.
  //   if (parsedRadius > 20.0) {
  //     radiusKm = parsedRadius / 1000.0;
  //   } else if (parsedRadius > 0) {
  //     radiusKm = parsedRadius;
  //   } else {
  //     radiusKm = 4.0; // default 4 km
  //   }
  //
  //   final center = Geoflutterfire().point(latitude: centerLat, longitude: centerLng);
  //
  //   // helper: extract GeoPoint robustly
  //   GeoPoint? _extractGeoPoint(dynamic pos) {
  //     try {
  //       if (pos == null) return null;
  //       if (pos is GeoPoint) return pos;
  //       if (pos is Map) {
  //         if (pos['geopoint'] is GeoPoint) return pos['geopoint'];
  //         if (pos.containsKey('geopoint') && pos['geopoint'] is Map) {
  //           final gp = pos['geopoint'];
  //           final lat = (gp['latitude'] ?? gp['lat'])?.toDouble();
  //           final lng = (gp['longitude'] ?? gp['lng'] ?? gp['lon'])?.toDouble();
  //           if (lat != null && lng != null) return GeoPoint(lat, lng);
  //         }
  //         if (pos.containsKey('latitude') && pos.containsKey('longitude')) {
  //           final lat = (pos['latitude'] as num).toDouble();
  //           final lng = (pos['longitude'] as num).toDouble();
  //           return GeoPoint(lat, lng);
  //         }
  //       }
  //       if (pos is List && pos.length >= 2) {
  //         final lat = (pos[0] as num).toDouble();
  //         final lng = (pos[1] as num).toDouble();
  //         return GeoPoint(lat, lng);
  //       }
  //     } catch (_) {
  //       // ignore parsing errors
  //     }
  //     return null;
  //   }
  //
  //   double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  //     const R = 6371.0;
  //     double toRad(double deg) => deg * (3.14159265358979323846 / 180.0);
  //     final dLat = toRad(lat2 - lat1);
  //     final dLon = toRad(lon2 - lon1);
  //     final a = (sin(dLat / 2) * sin(dLat / 2)) +
  //         cos(toRad(lat1)) * cos(toRad(lat2)) * (sin(dLon / 2) * sin(dLon / 2));
  //     final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  //     return R * c;
  //   }
  //
  //   Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
  //       .collection(collectionRef: serviceQuery)
  //       .within(center: center, radius: radiusKm, field: 'position', strictMode: true);
  //
  //   stream.listen((List<DocumentSnapshot> documentList) {
  //     ordersList.clear();
  //
  //     for (final document in documentList) {
  //       final data = document.data() as Map<String, dynamic>;
  //       OrderModel orderModel;
  //       try {
  //         orderModel = OrderModel.fromJson(data);
  //       } catch (e) {
  //         AppLogger.debug("Failed to parse order ${document.id}: $e", tag: "FireStoreUtils");
  //         continue;
  //       }
  //
  //       final geo = _extractGeoPoint(data['position']);
  //       if (geo == null) {
  //         AppLogger.debug("Order ${orderModel.id} missing geopoint, skipping.", tag: "FireStoreUtils");
  //         continue;
  //       }
  //
  //       final docLat = geo.latitude;
  //       final docLng = geo.longitude;
  //       final distKm = _haversineKm(centerLat, centerLng, docLat, docLng);
  //
  //       // log ride id, offerRate, distance
  //       final offerVal = data['offerRate'] ?? orderModel.offerRate ?? '';
  //       AppLogger.debug("Order ${orderModel.id} offerRate=$offerVal distance=${distKm.toStringAsFixed(3)} km", tag: "FireStoreUtils");
  //
  //       // flag suspicious raw positions
  //       if (distKm > 50.0) {
  //         AppLogger.debug("RAW POSITION for ${orderModel.id}: ${data['position']}", tag: "FireStoreUtils");
  //       }
  //
  //       // enforce radius with small epsilon
  //       const epsilon = 0.01; // 10m tolerance
  //       if (distKm > radiusKm + epsilon) {
  //         AppLogger.debug("Order ${orderModel.id} excluded by hard distance check (dist=${distKm.toStringAsFixed(3)} > radius=${radiusKm.toStringAsFixed(3)})", tag: "FireStoreUtils");
  //         continue;
  //       }
  //
  //       // acceptedDriverId logic
  //       final acceptedRaw = data['acceptedDriverId'];
  //       if (acceptedRaw != null) {
  //         bool containsCurrent = false;
  //         try {
  //           if (acceptedRaw is List) containsCurrent = acceptedRaw.contains(FireStoreUtils.getCurrentUid());
  //           else if (acceptedRaw is String) containsCurrent = acceptedRaw.contains(FireStoreUtils.getCurrentUid());
  //         } catch (_) {}
  //
  //         if (acceptedRaw is List && acceptedRaw.isNotEmpty && !containsCurrent) {
  //           AppLogger.debug("Order ${orderModel.id} already accepted by other driver(s), skipping.", tag: "FireStoreUtils");
  //           continue;
  //         }
  //       }
  //
  //       ordersList.add(orderModel);
  //     }
  //
  //     AppLogger.info("Nearest orders updated: ${ordersList.length} orders", tag: "FireStoreUtils");
  //     getNearestOrderRequestController!.sink.add(ordersList);
  //   }, onError: (e, s) {
  //     AppLogger.error("getOrders stream error: $e", tag: "FireStoreUtils", error: e, stackTrace: s);
  //   });
  //
  //   yield* getNearestOrderRequestController!.stream;
  // }

  // ************************************************************************************************************
  Stream<List<OrderModel>> getOrders(
      DriverUserModel driverUserModel, double? latitude, double? longitude) {
    AppLogger.debug("getOrders called for driver: ${driverUserModel.id}",
        tag: "FireStoreUtils");
    AppLogger.debug(
        "DEBUG center used: ($latitude, $longitude), Constant.radius='${Constant.radius}'",
        tag: "FireStoreUtils");

    if (latitude == null || longitude == null) {
      AppLogger.debug("Location not available", tag: "FireStoreUtils");
      return Stream.value(<OrderModel>[]);
    }

    if (driverUserModel.zoneIds == null || driverUserModel.zoneIds!.isEmpty) {
      AppLogger.debug("No zones assigned to driver", tag: "FireStoreUtils");
      return Stream.value(<OrderModel>[]);
    }

    Query<Map<String, dynamic>> baseQuery = fireStore
        .collection(CollectionName.orders)
        .where('zoneId', whereIn: driverUserModel.zoneIds)
        .where('status', isEqualTo: Constant.ridePlaced);

    Query<Map<String, dynamic>> serviceQuery = baseQuery;
    if (driverUserModel.serviceId != null &&
        driverUserModel.serviceId!.toString().trim().isNotEmpty) {
      serviceQuery =
          baseQuery.where('serviceId', isEqualTo: driverUserModel.serviceId);
    }

    final double centerLat = latitude!;
    final double centerLng = longitude!;
    double radiusKm;
    final parsedRadius = double.tryParse(Constant.radius ?? "") ?? 0.0;

    if (parsedRadius > 100.0) {
      radiusKm = parsedRadius / 1000.0;
    } else if (parsedRadius > 0) {
      radiusKm = parsedRadius;
    } else {
      radiusKm = 4.0;
    }

    AppLogger.debug("Using radius: ${radiusKm}km", tag: "FireStoreUtils");

    return serviceQuery.snapshots().map((snapshot) {
      AppLogger.info(
          "Received a new snapshot from Firestore. Total documents: ${snapshot.docs.length}",
          tag: "FireStoreUtils");
      List<OrderModel> ordersList = <OrderModel>[];

      for (DocumentSnapshot doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final GeoPoint? orderLocation = _extractGeoPoint(data['position']);
            if (orderLocation != null) {
              final double actualDistance = _calculateHaversineDistance(
                  centerLat,
                  centerLng,
                  orderLocation.latitude,
                  orderLocation.longitude);

              AppLogger.debug(
                  "Order ${doc.id}: Driver coords=($centerLat, $centerLng), Order coords=(${orderLocation.latitude}, ${orderLocation.longitude}), distance=${actualDistance.toStringAsFixed(2)}km",
                  tag: "FireStoreUtils");

              if (actualDistance <= radiusKm) {
                final OrderModel order = OrderModel.fromJson(data);
                ordersList.add(order);
              } else {
                AppLogger.debug(
                    "Order ${doc.id} excluded by distance check (${actualDistance.toStringAsFixed(2)}km > ${radiusKm}km)",
                    tag: "FireStoreUtils");
              }
            } else {
              // If we can't extract position, include it anyway (fallback)
              final OrderModel order = OrderModel.fromJson(data);
              ordersList.add(order);
            }
          }
        } catch (e) {
          AppLogger.debug("Error parsing order ${doc.id}: $e",
              tag: "FireStoreUtils");
        }
      }

      AppLogger.debug(
          "Yielding ${ordersList.length} orders after manual filtering.",
          tag: "FireStoreUtils");
      return ordersList;
    });
  }

  double _calculateHaversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    AppLogger.debug(
        "Calculating Haversine distance for coordinates: ($lat1, $lon1) and ($lat2, $lon2)",
        tag: "FireStoreUtils");
    const double earthRadiusKm = 6371.0;

    final double dLat = (lat2 - lat1) * (math.pi / 180);
    final double dLon = (lon2 - lon1) * (math.pi / 180);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) *
            math.cos(lat2 * (math.pi / 180)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    final double distance = earthRadiusKm * c;
    AppLogger.debug("Haversine distance calculated: ${distance} km",
        tag: "FireStoreUtils");
    return distance;
  }

  GeoPoint? _extractGeoPoint(dynamic pos) {
    AppLogger.debug(
        "Attempting to extract GeoPoint from data of type: ${pos.runtimeType}",
        tag: "FireStoreUtils");
    try {
      if (pos == null) {
        AppLogger.debug("GeoPoint extraction: input is null",
            tag: "FireStoreUtils");
        return null;
      }
      if (pos is GeoPoint) {
        AppLogger.debug("GeoPoint extraction: input is already a GeoPoint",
            tag: "FireStoreUtils");
        return pos;
      }
      if (pos is Map) {
        AppLogger.debug(
            "GeoPoint extraction: input is a Map. Checking for 'geopoint' key.",
            tag: "FireStoreUtils");
        if (pos['geopoint'] is GeoPoint) {
          AppLogger.debug(
              "GeoPoint extraction: found GeoPoint at 'geopoint' key",
              tag: "FireStoreUtils");
          return pos['geopoint'];
        }
        if (pos.containsKey('geopoint') && pos['geopoint'] is Map) {
          AppLogger.debug(
              "GeoPoint extraction: found nested Map at 'geopoint' key",
              tag: "FireStoreUtils");
          final gp = pos['geopoint'];
          final lat = (gp['latitude'] ?? gp['lat'])?.toDouble();
          final lng = (gp['longitude'] ?? gp['lng'] ?? gp['lon'])?.toDouble();
          if (lat != null && lng != null) {
            AppLogger.debug("GeoPoint extracted from nested map: ($lat, $lng)",
                tag: "FireStoreUtils");
            return GeoPoint(lat, lng);
          }
        }
        if (pos.containsKey('latitude') && pos.containsKey('longitude')) {
          AppLogger.debug(
              "GeoPoint extraction: found 'latitude' and 'longitude' keys directly in map",
              tag: "FireStoreUtils");
          final lat = (pos['latitude'] as num).toDouble();
          final lng = (pos['longitude'] as num).toDouble();
          AppLogger.debug("GeoPoint extracted from map: ($lat, $lng)",
              tag: "FireStoreUtils");
          return GeoPoint(lat, lng);
        }
      }
      if (pos is List && pos.length >= 2) {
        AppLogger.debug(
            "GeoPoint extraction: input is a List. Assuming [lat, lng] format.",
            tag: "FireStoreUtils");
        final lat = (pos[0] as num).toDouble();
        final lng = (pos[1] as num).toDouble();
        AppLogger.debug("GeoPoint extracted from list: ($lat, $lng)",
            tag: "FireStoreUtils");
        return GeoPoint(lat, lng);
      }
    } catch (e, s) {
      AppLogger.warning("GeoPoint extraction failed with error: $e",
          tag: "FireStoreUtils");
    }
    AppLogger.debug("GeoPoint extraction failed, returning null.",
        tag: "FireStoreUtils");
    return null;
  }
  //*************************************************************************************************************

  // Stream<List<OrderModel>> getOrders(DriverUserModel driverUserModel,
  //     double? latitude, double? longLatitude) async* {
  //   AppLogger.debug("getOrders called for driver: ${driverUserModel.id}, location: ($latitude, $longLatitude)", tag: "FireStoreUtils");
  //   getNearestOrderRequestController =
  //   StreamController<List<OrderModel>>.broadcast();
  //   List<OrderModel> ordersList = [];
  //   Query<Map<String, dynamic>> query = fireStore
  //       .collection(CollectionName.orders)
  //       .where('serviceId', isEqualTo: driverUserModel.serviceId)
  //       .where('zoneId', whereIn: driverUserModel.zoneIds)
  //       .where('status', isEqualTo: Constant.ridePlaced);
  //   GeoFirePoint center = Geoflutterfire()
  //       .point(latitude: latitude ?? 0.0, longitude: longLatitude ?? 0.0);
  //   Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
  //       .collection(collectionRef: query)
  //       .within(
  //       center: center,
  //       radius: double.parse(Constant.radius),
  //       field: 'position',
  //       strictMode: true,
  //   );
  //
  //   stream.listen((List<DocumentSnapshot> documentList) {
  //     ordersList.clear();
  //     for (var document in documentList) {
  //       final data = document.data() as Map<String, dynamic>;
  //       OrderModel orderModel = OrderModel.fromJson(data);
  //       if (orderModel.acceptedDriverId != null &&
  //           orderModel.acceptedDriverId!.isNotEmpty) {
  //         if (!orderModel.acceptedDriverId!
  //             .contains(FireStoreUtils.getCurrentUid())) {
  //           ordersList.add(orderModel);
  //         } else {
  //           AppLogger.debug("Order ${orderModel.id} already accepted by current driver, skipping.", tag: "FireStoreUtils");
  //         }
  //       } else {
  //         ordersList.add(orderModel);
  //       }
  //     }
  //     AppLogger.info("Nearest orders updated: ${ordersList.length} new orders.", tag: "FireStoreUtils");
  //     getNearestOrderRequestController!.sink.add(ordersList);
  //   }, onError: (error, s) {
  //     AppLogger.error("Error in getOrders stream: $error", tag: "FireStoreUtils", error: error, stackTrace: s);
  //   });
  //
  //   yield* getNearestOrderRequestController!.stream;
  // }

  StreamController<List<InterCityOrderModel>>?
      getNearestFreightOrderRequestController;

  Stream<List<InterCityOrderModel>> getFreightOrders(
      double? latitude, double? longLatitude) async* {
    AppLogger.debug(
        "getFreightOrders called for location: ($latitude, $longLatitude)",
        tag: "FireStoreUtils");
    getNearestFreightOrderRequestController =
        StreamController<List<InterCityOrderModel>>.broadcast();
    List<InterCityOrderModel> ordersList = [];
    Query<Map<String, dynamic>> query = fireStore
        .collection(CollectionName.ordersIntercity)
        .where('intercityServiceId', isEqualTo: "Kn2VEnPI3ikF58uK8YqY")
        .where('status', isEqualTo: Constant.ridePlaced);
    GeoFirePoint center = Geoflutterfire()
        .point(latitude: latitude ?? 0.0, longitude: longLatitude ?? 0.0);
    Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
        .collection(collectionRef: query)
        .within(
            center: center,
            radius: double.parse(Constant.radius),
            field: 'position',
            strictMode: true);

    stream.listen((List<DocumentSnapshot> documentList) {
      ordersList.clear();
      for (var document in documentList) {
        final data = document.data() as Map<String, dynamic>;
        InterCityOrderModel orderModel = InterCityOrderModel.fromJson(data);
        if (orderModel.acceptedDriverId != null &&
            orderModel.acceptedDriverId!.isNotEmpty) {
          if (!orderModel.acceptedDriverId!
              .contains(FireStoreUtils.getCurrentUid())) {
            ordersList.add(orderModel);
          } else {
            AppLogger.debug(
                "Intercity order ${orderModel.id} already accepted by current driver, skipping.",
                tag: "FireStoreUtils");
          }
        } else {
          ordersList.add(orderModel);
        }
      }
      AppLogger.info(
          "Nearest freight orders updated: ${ordersList.length} new orders.",
          tag: "FireStoreUtils");
      getNearestFreightOrderRequestController!.sink.add(ordersList);
    }, onError: (error, s) {
      AppLogger.error("Error in getFreightOrders stream: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    });

    yield* getNearestFreightOrderRequestController!.stream;
  }

  closeStream() {
    AppLogger.debug("closeStream called for nearest order requests.",
        tag: "FireStoreUtils");
    if (getNearestOrderRequestController != null) {
      getNearestOrderRequestController!.close();
      AppLogger.info("Nearest order request stream closed.",
          tag: "FireStoreUtils");
    }
  }

  closeFreightStream() {
    AppLogger.debug(
        "closeFreightStream called for nearest freight order requests.",
        tag: "FireStoreUtils");
    if (getNearestFreightOrderRequestController != null) {
      getNearestFreightOrderRequestController!.close();
      AppLogger.info("Nearest freight order request stream closed.",
          tag: "FireStoreUtils");
    }
  }

  static Future<bool?> setOrder(OrderModel orderModel) async {
    AppLogger.debug("setOrder called for order ID: ${orderModel.id}",
        tag: "FireStoreUtils");
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderModel.id)
        .set(orderModel.toJson())
        .then((value) {
      isAdded = true;
      AppLogger.info("Order ${orderModel.id} set successfully.",
          tag: "FireStoreUtils");
    }).catchError((error, s) {
      AppLogger.error("Failed to set order ${orderModel.id}: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> bankDetailsIsAvailable() async {
    AppLogger.debug(
        "bankDetailsIsAvailable called for current UID: ${getCurrentUid()}",
        tag: "FireStoreUtils");
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.bankDetails)
        .doc(FireStoreUtils.getCurrentUid())
        .get()
        .then((value) {
      if (value.exists) {
        isAdded = true;
        AppLogger.info("Bank details found for current UID.",
            tag: "FireStoreUtils");
      } else {
        isAdded = false;
        AppLogger.info("No bank details found for current UID.",
            tag: "FireStoreUtils");
      }
    }).catchError((error, s) {
      AppLogger.error("Failed to check bank details availability: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
      isAdded = false;
    });
    return isAdded;
  }

  static Future<OrderModel?> getOrder(String orderId) async {
    AppLogger.debug("getOrder called for order ID: $orderId",
        tag: "FireStoreUtils");
    OrderModel? orderModel;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderId)
        .get()
        .then((value) {
      if (value.data() != null) {
        orderModel = OrderModel.fromJson(value.data()!);
        AppLogger.info("Order data retrieved for ID: $orderId",
            tag: "FireStoreUtils");
      } else {
        AppLogger.warning("Order document not found for ID: $orderId",
            tag: "FireStoreUtils");
      }
    }).catchError((error, s) {
      AppLogger.error("Error getting order data for ID $orderId: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    });
    return orderModel;
  }

  static Future<InterCityOrderModel?> getInterCityOrder(String orderId) async {
    AppLogger.debug("getInterCityOrder called for order ID: $orderId",
        tag: "FireStoreUtils");
    InterCityOrderModel? orderModel;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderId)
        .get()
        .then((value) {
      if (value.data() != null) {
        orderModel = InterCityOrderModel.fromJson(value.data()!);
        AppLogger.info("Intercity order data retrieved for ID: $orderId",
            tag: "FireStoreUtils");
      } else {
        AppLogger.warning("Intercity order document not found for ID: $orderId",
            tag: "FireStoreUtils");
      }
    }).catchError((error, s) {
      AppLogger.error(
          "Error getting intercity order data for ID $orderId: $error",
          tag: "FireStoreUtils",
          error: error,
          stackTrace: s);
    });
    return orderModel;
  }

  static Future<bool?> acceptRide(
      OrderModel orderModel, DriverIdAcceptReject driverIdAcceptReject) async {
    AppLogger.debug(
        "acceptRide called for order ID: ${orderModel.id}, driver ID: ${driverIdAcceptReject.driverId}",
        tag: "FireStoreUtils");
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderModel.id)
        .collection("acceptedDriver")
        .doc(driverIdAcceptReject.driverId)
        .set(driverIdAcceptReject.toJson())
        .then((value) {
      isAdded = true;
      AppLogger.info(
          "Ride accepted successfully for order ID: ${orderModel.id}",
          tag: "FireStoreUtils");
    }).catchError((error, s) {
      AppLogger.error(
          "Failed to accept ride for order ID ${orderModel.id}: $error",
          tag: "FireStoreUtils",
          error: error,
          stackTrace: s);
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> setReview(ReviewModel reviewModel) async {
    AppLogger.debug("setReview called for review ID: ${reviewModel.id}",
        tag: "FireStoreUtils");
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.reviewCustomer)
        .doc(reviewModel.id)
        .set(reviewModel.toJson())
        .then((value) {
      isAdded = true;
      AppLogger.info("Review set successfully for ID: ${reviewModel.id}",
          tag: "FireStoreUtils");
    }).catchError((error, s) {
      AppLogger.error("Failed to set review for ID ${reviewModel.id}: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
      isAdded = false;
    });
    return isAdded;
  }

  static Future<ReviewModel?> getReview(String orderId) async {
    AppLogger.debug("getReview called for order ID: $orderId",
        tag: "FireStoreUtils");
    ReviewModel? reviewModel;
    await fireStore
        .collection(CollectionName.reviewCustomer)
        .doc(orderId)
        .get()
        .then((value) {
      if (value.data() != null) {
        reviewModel = ReviewModel.fromJson(value.data()!);
        AppLogger.info("Review data retrieved for order ID: $orderId",
            tag: "FireStoreUtils");
      } else {
        AppLogger.warning("Review document not found for order ID: $orderId",
            tag: "FireStoreUtils");
      }
    }).catchError((error, s) {
      AppLogger.error("Error getting review data for order ID $orderId: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    });
    return reviewModel;
  }

  static Future<bool?> setInterCityOrder(InterCityOrderModel orderModel) async {
    AppLogger.debug("setInterCityOrder called for order ID: ${orderModel.id}",
        tag: "FireStoreUtils");
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderModel.id)
        .set(orderModel.toJson())
        .then((value) {
      isAdded = true;
      AppLogger.info("Intercity order ${orderModel.id} set successfully.",
          tag: "FireStoreUtils");
    }).catchError((error, s) {
      AppLogger.error("Failed to set intercity order ${orderModel.id}: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> acceptInterCityRide(InterCityOrderModel orderModel,
      DriverIdAcceptReject driverIdAcceptReject) async {
    AppLogger.debug(
        "acceptInterCityRide called for order ID: ${orderModel.id}, driver ID: ${driverIdAcceptReject.driverId}",
        tag: "FireStoreUtils");
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderModel.id)
        .collection("acceptedDriver")
        .doc(driverIdAcceptReject.driverId)
        .set(driverIdAcceptReject.toJson())
        .then((value) {
      isAdded = true;
      AppLogger.info(
          "Intercity ride accepted successfully for order ID: ${orderModel.id}",
          tag: "FireStoreUtils");
    }).catchError((error, s) {
      AppLogger.error(
          "Failed to accept intercity ride for order ID ${orderModel.id}: $error",
          tag: "FireStoreUtils",
          error: error,
          stackTrace: s);
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<WalletTransactionModel>> getWalletTransaction() async {
    AppLogger.debug(
        "getWalletTransaction called for current UID: ${getCurrentUid()}",
        tag: "FireStoreUtils");
    List<WalletTransactionModel> walletTransactionModel = [];

    try {
      await fireStore
          .collection(CollectionName.walletTransaction)
          .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
          .orderBy('createdDate', descending: true)
          .get()
          .then((value) {
        for (var element in value.docs) {
          WalletTransactionModel taxModel =
              WalletTransactionModel.fromJson(element.data());
          walletTransactionModel.add(taxModel);
        }
        AppLogger.info(
            "Retrieved ${walletTransactionModel.length} wallet transactions.",
            tag: "FireStoreUtils");
      });
    } catch (error, s) {
      AppLogger.error("Error getting wallet transactions: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    }
    return walletTransactionModel;
  }

  static Future<bool?> setWalletTransaction(
      WalletTransactionModel walletTransactionModel) async {
    AppLogger.debug(
        "setWalletTransaction called for ID: ${walletTransactionModel.id}",
        tag: "FireStoreUtils");
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.walletTransaction)
        .doc(walletTransactionModel.id)
        .set(walletTransactionModel.toJson())
        .then((value) {
      isAdded = true;
      AppLogger.info(
          "Wallet transaction ${walletTransactionModel.id} set successfully.",
          tag: "FireStoreUtils");
    }).catchError((error, s) {
      AppLogger.error(
          "Failed to set wallet transaction ${walletTransactionModel.id}: $error",
          tag: "FireStoreUtils",
          error: error,
          stackTrace: s);
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> updatedDriverWallet({required String amount}) async {
    AppLogger.debug("updatedDriverWallet called with amount: $amount",
        tag: "FireStoreUtils");
    bool isAdded = false;
    await getDriverProfile(FireStoreUtils.getCurrentUid()).then((value) async {
      if (value != null) {
        DriverUserModel userModel = value;
        userModel.walletAmount =
            (double.parse(userModel.walletAmount.toString()) +
                    double.parse(amount))
                .toString();
        await FireStoreUtils.updateDriverUser(userModel).then((value) {
          isAdded = value;
          AppLogger.info("Driver wallet updated successfully for current UID.",
              tag: "FireStoreUtils");
        });
      } else {
        AppLogger.warning(
            "Driver profile not found when trying to update wallet.",
            tag: "FireStoreUtils");
      }
    }).catchError((error, s) {
      AppLogger.error("Error updating driver wallet: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    });
    return isAdded;
  }

  static Future<List<LanguageModel>?> getLanguage() async {
    AppLogger.debug("getLanguage called.", tag: "FireStoreUtils");
    List<LanguageModel> languageList = [];

    try {
      await fireStore
          .collection(CollectionName.languages)
          .where("enable", isEqualTo: true)
          .where("isDeleted", isEqualTo: false)
          .get()
          .then((value) {
        for (var element in value.docs) {
          LanguageModel taxModel = LanguageModel.fromJson(element.data());
          languageList.add(taxModel);
        }
        AppLogger.info("Retrieved ${languageList.length} languages.",
            tag: "FireStoreUtils");
      });
    } catch (error, s) {
      AppLogger.error("Error getting languages: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    }
    return languageList;
  }

  static Future<List<OnBoardingModel>> getOnBoardingList() async {
    AppLogger.debug("getOnBoardingList called.", tag: "FireStoreUtils");
    List<OnBoardingModel> onBoardingModel = [];
    await fireStore
        .collection(CollectionName.onBoarding)
        .where("type", isEqualTo: "driverApp")
        .get()
        .then((value) {
      for (var element in value.docs) {
        OnBoardingModel documentModel =
            OnBoardingModel.fromJson(element.data());
        onBoardingModel.add(documentModel);
      }
      AppLogger.info("Retrieved ${onBoardingModel.length} onboarding items.",
          tag: "FireStoreUtils");
    }).catchError((error, s) {
      AppLogger.error("Error getting onboarding list: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    });
    return onBoardingModel;
  }

  static Future addInBox(InboxModel inboxModel) async {
    AppLogger.debug("addInBox called for order ID: ${inboxModel.orderId}",
        tag: "FireStoreUtils");
    return await fireStore
        .collection(CollectionName.chat)
        .doc(inboxModel.orderId)
        .set(inboxModel.toJson())
        .then((document) {
      AppLogger.info("Inbox added/updated for order ID: ${inboxModel.orderId}",
          tag: "FireStoreUtils");
      return inboxModel;
    }).catchError((error, s) {
      AppLogger.error(
          "Error adding inbox for order ID ${inboxModel.orderId}: $error",
          tag: "FireStoreUtils",
          error: error,
          stackTrace: s);
      return null;
    });
  }

  static Future addChat(ConversationModel conversationModel) async {
    AppLogger.debug(
        "addChat called for conversation ID: ${conversationModel.id}, order ID: ${conversationModel.orderId}",
        tag: "FireStoreUtils");
    return await fireStore
        .collection(CollectionName.chat)
        .doc(conversationModel.orderId)
        .collection("thread")
        .doc(conversationModel.id)
        .set(conversationModel.toJson())
        .then((document) {
      AppLogger.info(
          "Chat message added for conversation ID: ${conversationModel.id}",
          tag: "FireStoreUtils");
      return conversationModel;
    }).catchError((error, s) {
      AppLogger.error(
          "Error adding chat message for conversation ID ${conversationModel.id}: $error",
          tag: "FireStoreUtils",
          error: error,
          stackTrace: s);
      return null;
    });
  }

  static Future<BankDetailsModel?> getBankDetails() async {
    AppLogger.debug("getBankDetails called for current UID: ${getCurrentUid()}",
        tag: "FireStoreUtils");
    BankDetailsModel? bankDetailsModel;
    await fireStore
        .collection(CollectionName.bankDetails)
        .doc(FireStoreUtils.getCurrentUid())
        .get()
        .then((value) {
      if (value.data() != null) {
        bankDetailsModel = BankDetailsModel.fromJson(value.data()!);
        AppLogger.info("Bank details retrieved for current UID.",
            tag: "FireStoreUtils");
      } else {
        AppLogger.warning("Bank details not found for current UID.",
            tag: "FireStoreUtils");
      }
    }).catchError((error, s) {
      AppLogger.error("Error getting bank details: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    });
    return bankDetailsModel;
  }

  static Future<bool?> updateBankDetails(
      BankDetailsModel bankDetailsModel) async {
    AppLogger.debug(
        "updateBankDetails called for user ID: ${bankDetailsModel.userId}",
        tag: "FireStoreUtils");
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.bankDetails)
        .doc(bankDetailsModel.userId)
        .set(bankDetailsModel.toJson())
        .then((value) {
      isAdded = true;
      AppLogger.info(
          "Bank details updated successfully for user ID: ${bankDetailsModel.userId}",
          tag: "FireStoreUtils");
    }).catchError((error, s) {
      AppLogger.error(
          "Failed to update bank details for user ID ${bankDetailsModel.userId}: $error",
          tag: "FireStoreUtils",
          error: error,
          stackTrace: s);
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> setWithdrawRequest(WithdrawModel withdrawModel) async {
    AppLogger.debug("setWithdrawRequest called for ID: ${withdrawModel.id}",
        tag: "FireStoreUtils");
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.withdrawalHistory)
        .doc(withdrawModel.id)
        .set(withdrawModel.toJson())
        .then((value) {
      isAdded = true;
      AppLogger.info("Withdraw request ${withdrawModel.id} set successfully.",
          tag: "FireStoreUtils");
    }).catchError((error, s) {
      AppLogger.error(
          "Failed to set withdraw request ${withdrawModel.id}: $error",
          tag: "FireStoreUtils",
          error: error,
          stackTrace: s);
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<WithdrawModel>> getWithDrawRequest() async {
    AppLogger.debug(
        "getWithDrawRequest called for current UID: ${getCurrentUid()}",
        tag: "FireStoreUtils");
    List<WithdrawModel> withdrawalList = [];
    try {
      await fireStore
          .collection(CollectionName.withdrawalHistory)
          .where('userId', isEqualTo: getCurrentUid())
          .orderBy('createdDate', descending: true)
          .get()
          .then((value) {
        for (var element in value.docs) {
          WithdrawModel documentModel = WithdrawModel.fromJson(element.data());
          withdrawalList.add(documentModel);
        }
        AppLogger.info(
            "Retrieved ${withdrawalList.length} withdrawal requests.",
            tag: "FireStoreUtils");
      });
    } catch (error, s) {
      AppLogger.error("Error getting withdrawal requests: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    }
    return withdrawalList;
  }

  static Future<bool?> deleteUser() async {
    AppLogger.debug("deleteUser called for current UID: ${getCurrentUid()}",
        tag: "FireStoreUtils");
    bool? isDelete;
    try {
      await fireStore
          .collection(CollectionName.driverUsers)
          .doc(FireStoreUtils.getCurrentUid())
          .delete();
      AppLogger.info(
          "Driver user document deleted from Firestore for current UID.",
          tag: "FireStoreUtils");

      // delete user  from firebase auth
      await FirebaseAuth.instance.currentUser!.delete().then((value) {
        isDelete = true;
        AppLogger.info("Firebase Auth user deleted for current UID.",
            tag: "FireStoreUtils");
      });
    } catch (e, s) {
      AppLogger.error('FireStoreUtils.deleteUser $e $s',
          tag: "FireStoreUtils", error: e, stackTrace: s);
      return false;
    }
    return isDelete;
  }

  static Future<bool> getIntercityFirstOrderOrNOt(
      InterCityOrderModel orderModel) async {
    AppLogger.debug(
        "getIntercityFirstOrderOrNOt called for user ID: ${orderModel.userId}",
        tag: "FireStoreUtils");
    bool isFirst = true;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .where('userId', isEqualTo: orderModel.userId)
        .get()
        .then((value) {
      if (value.size == 1) {
        isFirst = true;
        AppLogger.info(
            "Intercity order is the first for user ID: ${orderModel.userId}",
            tag: "FireStoreUtils");
      } else {
        isFirst = false;
        AppLogger.info(
            "Intercity order is NOT the first for user ID: ${orderModel.userId}",
            tag: "FireStoreUtils");
      }
    }).catchError((error, s) {
      AppLogger.error("Error checking if intercity order is first: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    });
    return isFirst;
  }

  static Future updateIntercityReferralAmount(
      InterCityOrderModel orderModel) async {
    AppLogger.debug(
        "updateIntercityReferralAmount called for order ID: ${orderModel.id}",
        tag: "FireStoreUtils");
    ReferralModel? referralModel;
    await fireStore
        .collection(CollectionName.referral)
        .doc(orderModel.userId)
        .get()
        .then((value) {
      if (value.data() != null) {
        referralModel = ReferralModel.fromJson(value.data()!);
        AppLogger.info(
            "Referral model retrieved for user ID: ${orderModel.userId}",
            tag: "FireStoreUtils");
      } else {
        AppLogger.warning(
            "No referral model found for user ID: ${orderModel.userId}, skipping referral amount update.",
            tag: "FireStoreUtils");
        return;
      }
    }).catchError((error, s) {
      AppLogger.error(
          "Error getting referral model for intercity order: $error",
          tag: "FireStoreUtils",
          error: error,
          stackTrace: s);
      return;
    });
    if (referralModel != null) {
      if (referralModel!.referralBy != null &&
          referralModel!.referralBy!.isNotEmpty) {
        await fireStore
            .collection(CollectionName.users)
            .doc(referralModel!.referralBy)
            .get()
            .then((value) async {
          DocumentSnapshot<Map<String, dynamic>> userDocument = value;
          if (userDocument.data() != null && userDocument.exists) {
            try {
              UserModel user = UserModel.fromJson(userDocument.data()!);
              user.walletAmount = (double.parse(user.walletAmount.toString()) +
                      double.parse(Constant.referralAmount.toString()))
                  .toString();
              updateUser(user);

              WalletTransactionModel transactionModel = WalletTransactionModel(
                  id: Constant.getUuid(),
                  amount: Constant.referralAmount.toString(),
                  createdDate: Timestamp.now(),
                  paymentType: "Wallet",
                  transactionId: orderModel.id,
                  userId: orderModel.driverId.toString(),
                  orderType: "intercity",
                  userType: "customer",
                  note: "Referral Amount");

              await FireStoreUtils.setWalletTransaction(transactionModel);
              AppLogger.info(
                  "Intercity referral amount updated for user: ${user.id}",
                  tag: "FireStoreUtils");
            } catch (error, s) {
              AppLogger.error(
                  "Error updating intercity referral amount: $error",
                  tag: "FireStoreUtils",
                  error: error,
                  stackTrace: s);
            }
          } else {
            AppLogger.warning(
                "ReferralBy user document not found for intercity order referral.",
                tag: "FireStoreUtils");
          }
        }).catchError((error, s) {
          AppLogger.error(
              "Error fetching referralBy user for intercity order referral: $error",
              tag: "FireStoreUtils",
              error: error,
              stackTrace: s);
        });
      } else {
        AppLogger.info(
            "ReferralBy is null or empty for intercity order, skipping referral amount update.",
            tag: "FireStoreUtils");
        return;
      }
    }
  }

  static Future<bool> getFirestOrderOrNOt(OrderModel orderModel) async {
    AppLogger.debug(
        "getFirestOrderOrNOt called for user ID: ${orderModel.userId}",
        tag: "FireStoreUtils");
    bool isFirst = true;
    await fireStore
        .collection(CollectionName.orders)
        .where('userId', isEqualTo: orderModel.userId)
        .get()
        .then((value) {
      if (value.size == 1) {
        isFirst = true;
        AppLogger.info("Order is the first for user ID: ${orderModel.userId}",
            tag: "FireStoreUtils");
      } else {
        isFirst = false;
        AppLogger.info(
            "Order is NOT the first for user ID: ${orderModel.userId}",
            tag: "FireStoreUtils");
      }
    }).catchError((error, s) {
      AppLogger.error("Error checking if order is first: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
    });
    return isFirst;
  }

  static Future updateReferralAmount(OrderModel orderModel) async {
    AppLogger.debug(
        "updateReferralAmount called for order ID: ${orderModel.id}",
        tag: "FireStoreUtils");
    ReferralModel? referralModel;
    await fireStore
        .collection(CollectionName.referral)
        .doc(orderModel.userId)
        .get()
        .then((value) {
      if (value.data() != null) {
        referralModel = ReferralModel.fromJson(value.data()!);
        AppLogger.info(
            "Referral model retrieved for user ID: ${orderModel.userId}",
            tag: "FireStoreUtils");
      } else {
        AppLogger.warning(
            "No referral model found for user ID: ${orderModel.userId}, skipping referral amount update.",
            tag: "FireStoreUtils");
        return;
      }
    }).catchError((error, s) {
      AppLogger.error("Error getting referral model for order: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
      return;
    });
    if (referralModel != null) {
      if (referralModel!.referralBy != null &&
          referralModel!.referralBy!.isNotEmpty) {
        await fireStore
            .collection(CollectionName.users)
            .doc(referralModel!.referralBy)
            .get()
            .then((value) async {
          DocumentSnapshot<Map<String, dynamic>> userDocument = value;
          if (userDocument.data() != null && userDocument.exists) {
            try {
              UserModel user = UserModel.fromJson(userDocument.data()!);
              user.walletAmount = (double.parse(user.walletAmount.toString()) +
                      double.parse(Constant.referralAmount.toString()))
                  .toString();
              updateUser(user);

              WalletTransactionModel transactionModel = WalletTransactionModel(
                  id: Constant.getUuid(),
                  amount: Constant.referralAmount.toString(),
                  createdDate: Timestamp.now(),
                  paymentType: "Wallet",
                  transactionId: orderModel.id,
                  userId: orderModel.driverId.toString(),
                  orderType: "city",
                  userType: "customer",
                  note: "Referral Amount");

              await FireStoreUtils.setWalletTransaction(transactionModel);
              AppLogger.info("Referral amount updated for user: ${user.id}",
                  tag: "FireStoreUtils");
            } catch (error, s) {
              AppLogger.error("Error updating referral amount: $error",
                  tag: "FireStoreUtils", error: error, stackTrace: s);
              print(error);
            }
          } else {
            AppLogger.warning(
                "ReferralBy user document not found for order referral.",
                tag: "FireStoreUtils");
          }
        }).catchError((error, s) {
          AppLogger.error(
              "Error fetching referralBy user for order referral: $error",
              tag: "FireStoreUtils",
              error: error,
              stackTrace: s);
        });
      } else {
        AppLogger.info(
            "ReferralBy is null or empty for order, skipping referral amount update.",
            tag: "FireStoreUtils");
        return;
      }
    }
  }

  static Future<List<ZoneModel>?> getZone() async {
    AppLogger.debug("getZone called.", tag: "FireStoreUtils");
    List<ZoneModel> airPortList = [];
    await fireStore
        .collection(CollectionName.zone)
        .where('publish', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        ZoneModel ariPortModel = ZoneModel.fromJson(element.data());
        airPortList.add(ariPortModel);
      }
      AppLogger.info("Retrieved ${airPortList.length} zones.",
          tag: "FireStoreUtils");
    }).catchError((error, s) {
      AppLogger.error("Error getting zones: $error",
          tag: "FireStoreUtils", error: error, stackTrace: s);
      // log(error.toString());
    });
    return airPortList;
  }

  static Future<List<SubscriptionHistoryModel>> getSubscriptionHistory() async {
    List<SubscriptionHistoryModel> subscriptionHistoryList = [];
    await fireStore
        .collection(CollectionName.subscriptionHistory)
        .where('user_id', isEqualTo: getCurrentUid())
        .orderBy('createdAt', descending: true)
        .get()
        .then((value) async {
      if (value.docs.isNotEmpty) {
        for (var element in value.docs) {
          SubscriptionHistoryModel subscriptionHistoryModel =
              SubscriptionHistoryModel.fromJson(element.data(), element.id);
          subscriptionHistoryList.add(subscriptionHistoryModel);
        }
      }
    });
    return subscriptionHistoryList;
  }

  static Future<List<SubscriptionModel>> getAllSubscriptionPlans() async {
    AppLogger.debug("getAllSubscriptionPlans called.", tag: "FireStoreUtils");
    List<SubscriptionModel> subscriptionPlanList = [];
    try {
      await fireStore
          .collection(CollectionName.subscriptionPlan)
          .where('planFor', isEqualTo: 'driver')
          .get()
          .then((value) {
        for (var element in value.docs) {
          SubscriptionModel subscriptionModel =
              SubscriptionModel.fromJson(element.data(), element.id);
          subscriptionPlanList.add(subscriptionModel);
        }
        AppLogger.info(
            "Retrieved ${subscriptionPlanList.length} subscription plans.",
            tag: "FireStoreUtils");
      });
    } catch (e, s) {
      AppLogger.error("Error getting subscription plans: $e",
          tag: "FireStoreUtils", error: e, stackTrace: s);
    }
    return subscriptionPlanList;
  }

  static Future<bool> setSubscriptionTransaction(
      SubscriptionHistoryModel subscriptionHistoryModel) async {
    AppLogger.debug(
        "setSubscriptionTransaction called for ID: ${subscriptionHistoryModel.id}",
        tag: "FireStoreUtils");
    try {
      await fireStore
          .collection(CollectionName.subscriptionHistory)
          .doc(subscriptionHistoryModel.id)
          .set(subscriptionHistoryModel.toJson());
      AppLogger.info(
          "FireStoreUtils: Subscription transaction saved successfully for ID: ${subscriptionHistoryModel.id}",
          tag: "FireStoreUtils");
      return true;
    } catch (e, s) {
      AppLogger.error("FireStoreUtils: Error saving subscription transaction",
          tag: "FireStoreUtils", error: e, stackTrace: s);
      return false;
    }
  }
}
