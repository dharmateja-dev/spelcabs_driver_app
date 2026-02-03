import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/ui/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/ui/auth_screen/otp_screen.dart';
import 'package:driver/ui/dashboard_screen.dart';
import 'package:driver/ui/driver_location_permission_screen.dart';
import 'package:driver/utils/Preferences.dart';
import 'package:driver/utils/app_logger.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/ui/auth_screen/information_screen.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:uuid/uuid.dart';

class AuthApiService {
  static bool isDarkMode = Get.context != null &&
      (Theme.of(Get.context!).brightness == Brightness.dark);
  static void _showSnackbar(BuildContext context, String message) {
    AppLogger.info("Displaying Snackbar: $message", tag: "AuthApiService");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message,
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          duration: const Duration(seconds: 3)),
    );
  }

  static Future<void> _saveDriverUserDataToPreferences(
    DriverUserModel driverUser,
  ) async {
    AppLogger.info(
      "AuthApiService: Saving driver user data to preferences.",
      tag: "AuthApiService",
    );
    await Preferences.saveDriverUserData(driverUser);
    await Preferences.setBoolean(Constant.isLoggedInKey, true);
    AppLogger.info(
      "AuthApiService: Driver user data saved to preferences and isLoggedIn set to true.",
      tag: "AuthApiService",
    );
  }

  /// Helper method to check if driver profile is complete
  static bool _isProfileComplete(DriverUserModel driver) {
    return driver.fullName != null &&
        driver.fullName!.isNotEmpty &&
        driver.email != null &&
        driver.email!.isNotEmpty;
  }

  /// Initiates the login process for drivers using Firebase Phone Auth
  static Future<void> loginWithOtp(
    String countryCode,
    String phoneNumber,
    BuildContext context,
  ) async {
    AppLogger.info(
      "AuthApiService: Initiating loginWithOtp for driver $phoneNumber",
      tag: "AuthApiService",
    );

    ShowToastDialog.showLoader("Sending OTP...");

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "$countryCode$phoneNumber",
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto login when instant verification occurs
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          ShowToastDialog.closeLoader();
          _showSnackbar(context, e.message ?? "Failed to send OTP");
        },
        codeSent: (String verificationId, int? resendToken) {
          ShowToastDialog.closeLoader();
          AppLogger.info("Firebase: OTP sent successfully for login",
              tag: "AuthApiService");

          Get.to(() => const OtpScreen(), arguments: {
            "countryCode": countryCode,
            "phoneNumber": phoneNumber,
            "verificationId": verificationId,
            "isSignup": false,
          });

          _showSnackbar(context, "OTP sent successfully");
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e, s) {
      ShowToastDialog.closeLoader();
      _showSnackbar(context, 'An error occurred during driver login: $e');

      AppLogger.error("Error in loginWithOtp",
          tag: "AuthApiService", error: e, stackTrace: s);
    }
  }

  /// Initiates the signup process for drivers using Firebase Phone Auth
  static Future<void> signupWithOtp(
    String fullname,
    String countryCode,
    String phoneNumber,
    String email,
    BuildContext context,
  ) async {
    AppLogger.info(
      "AuthApiService: Initiating signupWithOtp for driver $fullname, $countryCode$phoneNumber, $email",
      tag: "AuthApiService",
    );

    ShowToastDialog.showLoader("Checking driver details...");

    try {
      // Check if email or phone already exists in both users and driver_users collections
      bool isRegistered = await FireStoreUtils.isEmailOrPhoneRegistered(
          email, countryCode, phoneNumber);
      if (isRegistered) {
        ShowToastDialog.closeLoader();
        _showSnackbar(
            context, "This email or phone number is already registered");
        return;
      }

      // Send OTP using Firebase
      ShowToastDialog.showLoader("Sending OTP...");

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "$countryCode$phoneNumber",
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          ShowToastDialog.closeLoader();
          _showSnackbar(context, e.message ?? "Failed to send OTP");
        },
        codeSent: (String verificationId, int? resendToken) {
          ShowToastDialog.closeLoader();
          AppLogger.info("Firebase: OTP sent successfully for signup",
              tag: "AuthApiService");

          Get.to(() => const OtpScreen(), arguments: {
            "phoneNumber": phoneNumber,
            "countryCode": countryCode,
            "verificationId": verificationId,
            "isSignup": true,
            "fullname": fullname,
            "email": email,
          });

          _showSnackbar(context, "OTP sent successfully");
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e, s) {
      ShowToastDialog.closeLoader();
      _showSnackbar(context, "An error occurred during signup: $e");

      AppLogger.error("Error in signupWithOtp",
          tag: "AuthApiService", error: e, stackTrace: s);
    }
  }

  /// Completes the signup process after Firebase OTP verification
  static Future<void> completeSignupWithOtp(
    String fullname,
    String countryCode,
    String phoneNumber,
    String email,
    BuildContext context,
  ) async {
    AppLogger.info(
      "AuthApiService: Starting completeSignupWithOtp for driver $fullname, $countryCode, $phoneNumber, $email",
      tag: "AuthApiService",
    );
    ShowToastDialog.showLoader("Completing driver signup...");

    try {
      // Double-check email/phone in both collections to prevent duplicates and race conditions
      bool isRegistered = await FireStoreUtils.isEmailOrPhoneRegistered(
          email, countryCode, phoneNumber);
      if (isRegistered) {
        ShowToastDialog.closeLoader();
        _showSnackbar(
            context, "This email or phone number is already registered");
        AppLogger.warning(
          "AuthApiService: Duplicate detected during completeSignup for $countryCode$phoneNumber / $email",
          tag: "AuthApiService",
        );
        return;
      }

      // Create new driver
      // Use Firebase Auth UID as the Document ID to maintain a "Single Identity" across apps
      String newUid =
          FirebaseAuth.instance.currentUser?.uid ?? const Uuid().v4();
      DriverUserModel newDriver = DriverUserModel(
        id: newUid,
        fullName: fullname,
        email: email.isEmpty ? null : email.toLowerCase(),
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        loginType: Constant.phoneLoginType,
        profilePic: Constant.userPlaceHolder,
        createdAt: Timestamp.now(),
        walletAmount: "0.0",
        reviewsCount: "0.0",
        reviewsSum: "0.0",
        fcmToken: "",
        documentVerification: false,
        isOnline: false,
        rotation: 0.0,
        zoneIds: [],
      );

      await FireStoreUtils.updateDriverUser(newDriver);
      await _saveDriverUserDataToPreferences(newDriver);
      FireStoreUtils.currentDriverUser = newDriver;

      ShowToastDialog.closeLoader();
      _showSnackbar(context, "Signup successful!");
      AppLogger.info(
        "AuthApiService: Driver signup completed. Navigating to DriverLocationPermissionScreen.",
        tag: "AuthApiService",
      );

      // First-time signup - show location permission screen
      Get.offAll(() => const DriverLocationPermissionScreen());
    } catch (e, s) {
      ShowToastDialog.closeLoader();
      _showSnackbar(
        context,
        'An error occurred during driver signup completion: $e',
      );
      AppLogger.error(
        "AuthApiService: Error in completeSignupWithOtp",
        tag: "AuthApiService",
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Completes the login process after Firebase OTP verification
  static Future<void> completeLoginWithOtp(
    String countryCode,
    String phoneNumber,
    BuildContext context,
  ) async {
    AppLogger.info(
      "AuthApiService: Starting completeLoginWithOtp for driver $countryCode, $phoneNumber",
      tag: "AuthApiService",
    );
    ShowToastDialog.showLoader("Completing driver login...");

    try {
      DriverUserModel? driverModel =
          await FireStoreUtils.getDriverProfileByPhoneNumber(
        countryCode,
        phoneNumber,
      );

      if (driverModel != null) {
        // Existing driver - check if profile is complete
        bool isProfileComplete = _isProfileComplete(driverModel);

        // Save user data
        await _saveDriverUserDataToPreferences(driverModel);
        FireStoreUtils.currentDriverUser = driverModel;

        ShowToastDialog.closeLoader();

        if (!isProfileComplete) {
          // Profile incomplete - redirect to Information Screen
          _showSnackbar(context, "Welcome! Please complete your profile.");
          AppLogger.info(
            "AuthApiService: Driver login successful but profile incomplete. Navigating to Information Screen.",
            tag: "AuthApiService",
          );
          Get.offAll(const InformationScreen(),
              arguments: {'driverModel': driverModel});
        } else {
          // Profile complete - proceed to dashboard
          _showSnackbar(context, "Login successful!");
          AppLogger.info(
            "AuthApiService: Driver login completed successfully. Navigating to Dashboard.",
            tag: "AuthApiService",
          );
          Get.offAll(const DashBoardScreen());
        }
      } else {
        ShowToastDialog.closeLoader();
        _showSnackbar(
          context,
          "No account found with this phone number. Please sign up.",
        );
        AppLogger.warning(
          "AuthApiService: Driver not found in Firestore for country code: $countryCode phone number: $phoneNumber",
          tag: "AuthApiService",
        );
        Get.offAll(() => const SplashScreen());
      }
    } catch (e, s) {
      ShowToastDialog.closeLoader();
      _showSnackbar(
        context,
        'An error occurred during driver login completion: $e',
      );
      AppLogger.error(
        "AuthApiService: Error in completeLoginWithOtp",
        tag: "AuthApiService",
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Handles Google Sign-in for drivers
  static Future<void> googleSignIn(BuildContext context) async {
    AppLogger.info(
      "AuthApiService: Starting Google Sign-in with Firebase Auth.",
      tag: "AuthApiService",
    );
    ShowToastDialog.showLoader("Signing in with Google...");

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        ShowToastDialog.closeLoader();
        AppLogger.info(
          "AuthApiService: Google Sign-in cancelled by user.",
          tag: "AuthApiService",
        );
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        AppLogger.info(
          "AuthApiService: Firebase Google Sign-in successful for UID: ${firebaseUser.uid}",
          tag: "AuthApiService",
        );

        DriverUserModel? driverModel =
            await FireStoreUtils.getDriverProfile(firebaseUser.uid);

        if (driverModel != null) {
          // Existing driver
          driverModel.fcmToken = await FirebaseMessaging.instance.getToken();
          await FireStoreUtils.updateDriverUser(driverModel);
          await _saveDriverUserDataToPreferences(driverModel);
          FireStoreUtils.currentDriverUser = driverModel;

          ShowToastDialog.closeLoader();
          _showSnackbar(context, "Google Sign-in successful!");

          Get.offAll(const DashBoardScreen());
        } else {
          // New driver - ensure email isn't already registered to another account
          if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
            // Check if email exists in driver_users collection
            DriverUserModel? existingByEmail =
                await FireStoreUtils.getDriverProfileByEmail(
                    firebaseUser.email!.toString());
            if (existingByEmail != null &&
                existingByEmail.id != firebaseUser.uid) {
              ShowToastDialog.closeLoader();
              _showSnackbar(context,
                  "An account with this email already exists. Please login with that account.");
              AppLogger.warning(
                  "AuthApiService: Email ${firebaseUser.email} already in use by driver ${existingByEmail.id}",
                  tag: "AuthApiService");
              return;
            }

            // Check if email exists in customers (users) collection - enforce "one email, one profile"
            bool existsInCustomers =
                await FireStoreUtils.isEmailRegisteredInCustomers(
                    firebaseUser.email!);
            if (existsInCustomers) {
              ShowToastDialog.closeLoader();
              _showSnackbar(context,
                  "This email is already registered as a customer. One account per email/phone is allowed.");
              AppLogger.warning(
                  "AuthApiService: Email ${firebaseUser.email} already registered as customer",
                  tag: "AuthApiService");
              return;
            }
          }

          // New driver
          DriverUserModel newDriver = DriverUserModel(
            id: firebaseUser.uid,
            fullName: firebaseUser.displayName,
            email: firebaseUser.email?.toLowerCase(),
            phoneNumber: firebaseUser.phoneNumber,
            profilePic: firebaseUser.photoURL ?? Constant.userPlaceHolder,
            loginType: Constant.googleLoginType,
            createdAt: Timestamp.now(),
            walletAmount: "0.0",
            reviewsCount: "0.0",
            reviewsSum: "0.0",
            documentVerification: false,
            isOnline: false,
            fcmToken: "",
            rotation: 0.0,
            zoneIds: [],
          );

          await FireStoreUtils.updateDriverUser(newDriver);
          await _saveDriverUserDataToPreferences(newDriver);
          FireStoreUtils.currentDriverUser = newDriver;

          ShowToastDialog.closeLoader();
          _showSnackbar(context,
              "Google Sign-up successful! Please complete your profile.");

          Get.offAll(const InformationScreen(),
              arguments: {'userModel': newDriver});
        }
      } else {
        ShowToastDialog.closeLoader();
        _showSnackbar(context, "Google Sign-in failed. User not found.");
      }
    } catch (e, s) {
      ShowToastDialog.closeLoader();
      _showSnackbar(context,
          'An error occurred during Google Sign-in: Please try again or check your internet connection');
      AppLogger.error(
        "AuthApiService: Error in Google Sign-in",
        tag: "AuthApiService",
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Handles Apple Sign-in for drivers
  static Future<void> appleSignIn(BuildContext context) async {
    AppLogger.info(
      "AuthApiService: Starting Apple Sign-in with Firebase Auth.",
      tag: "AuthApiService",
    );
    ShowToastDialog.showLoader("Signing in with Apple...");

    try {
      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthProvider oAuthProvider = OAuthProvider("apple.com");
      final AuthCredential credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        AppLogger.info(
          "AuthApiService: Firebase Apple Sign-in successful for UID: ${firebaseUser.uid}",
          tag: "AuthApiService",
        );

        DriverUserModel? driverModel =
            await FireStoreUtils.getDriverProfile(firebaseUser.uid);

        if (driverModel != null) {
          // Existing driver
          driverModel.fcmToken = await FirebaseMessaging.instance.getToken();
          await FireStoreUtils.updateDriverUser(driverModel);
          await _saveDriverUserDataToPreferences(driverModel);
          FireStoreUtils.currentDriverUser = driverModel;

          ShowToastDialog.closeLoader();
          _showSnackbar(context, "Apple Sign-in successful!");

          Get.offAll(const DashBoardScreen());
        } else {
          // New driver - ensure email isn't already registered to another account
          if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
            // Check if email exists in driver_users collection
            DriverUserModel? existingByEmail =
                await FireStoreUtils.getDriverProfileByEmail(
                    firebaseUser.email!.toString());
            if (existingByEmail != null &&
                existingByEmail.id != firebaseUser.uid) {
              ShowToastDialog.closeLoader();
              _showSnackbar(context,
                  "An account with this email already exists. Please login with that account.");
              AppLogger.warning(
                  "AuthApiService: Email ${firebaseUser.email} already in use by driver ${existingByEmail.id}",
                  tag: "AuthApiService");
              return;
            }

            // Check if email exists in customers (users) collection - enforce "one email, one profile"
            bool existsInCustomers =
                await FireStoreUtils.isEmailRegisteredInCustomers(
                    firebaseUser.email!);
            if (existsInCustomers) {
              ShowToastDialog.closeLoader();
              _showSnackbar(context,
                  "This email is already registered as a customer. One account per email/phone is allowed.");
              AppLogger.warning(
                  "AuthApiService: Email ${firebaseUser.email} already registered as customer",
                  tag: "AuthApiService");
              return;
            }
          }

          // New driver
          DriverUserModel newDriver = DriverUserModel(
            id: firebaseUser.uid,
            fullName: appleCredential.givenName != null &&
                    appleCredential.familyName != null
                ? '${appleCredential.givenName!} ${appleCredential.familyName!}'
                : firebaseUser.displayName,
            email: firebaseUser.email?.toLowerCase(),
            phoneNumber: firebaseUser.phoneNumber,
            profilePic: firebaseUser.photoURL ?? Constant.userPlaceHolder,
            loginType: Constant.appleLoginType,
            createdAt: Timestamp.now(),
            walletAmount: "0.0",
            reviewsCount: "0.0",
            reviewsSum: "0.0",
            documentVerification: false,
            isOnline: false,
            fcmToken: "",
            rotation: 0.0,
            zoneIds: [],
          );

          await FireStoreUtils.updateDriverUser(newDriver);
          await _saveDriverUserDataToPreferences(newDriver);
          FireStoreUtils.currentDriverUser = newDriver;

          ShowToastDialog.closeLoader();
          _showSnackbar(context,
              "Apple Sign-up successful! Please complete your profile.");

          Get.offAll(const InformationScreen(),
              arguments: {'userModel': newDriver});
        }
      } else {
        ShowToastDialog.closeLoader();
        _showSnackbar(context, "Apple Sign-in failed. User not found.");
      }
    } catch (e, s) {
      ShowToastDialog.closeLoader();
      _showSnackbar(context,
          'An error occurred during Apple Sign-in: Please try again or check your internet connection');
      AppLogger.error(
        "AuthApiService: Error in Apple Sign-in",
        tag: "AuthApiService",
        error: e,
        stackTrace: s,
      );
    }
  }
}
