import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/ui/auth_screen/information_screen.dart';
import 'package:driver/ui/auth_screen/login_screen.dart';
import 'package:driver/ui/dashboard_screen.dart';
import 'package:driver/ui/on_boarding_screen.dart';
import 'package:driver/utils/Preferences.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:get/get.dart';
import 'package:driver/utils/app_logger.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';

class SplashController extends GetxController {
  RxBool navigationFailed = false.obs;

  @override
  void onInit() {
    super.onInit();
    AppLogger.info("SplashController: Initializing.", tag: "SplashController");

    // CRITICAL FIX: Delay navigation until after first frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Add small additional delay to ensure Navigator is fully ready
      Future.delayed(const Duration(milliseconds: 100), () {
        redirectScreen();
      });
    });
  }

  Future<void> redirectScreen() async {
    AppLogger.info("SplashController: Redirecting screen.",
        tag: "SplashController");
    navigationFailed.value = false;

    try {
      // Check if onboarding is finished
      bool isFinishOnBoarding =
          Preferences.getBoolean(Preferences.isFinishOnBoardingKey);
      AppLogger.info(
          "SplashController: isFinishOnBoarding = $isFinishOnBoarding",
          tag: "SplashController");

      if (isFinishOnBoarding) {
        // Check if user is logged in via local preferences (for phone users)
        bool isLoggedInLocally = Preferences.getBoolean(Constant.isLoggedInKey);
        String? driverIdFromPrefs = Preferences.getString(Constant.driverIdKey);
        AppLogger.info(
            "SplashController: isLoggedInLocally = $isLoggedInLocally, driverIdFromPrefs = $driverIdFromPrefs",
            tag: "SplashController");

        if (isLoggedInLocally &&
            driverIdFromPrefs != null &&
            driverIdFromPrefs.isNotEmpty) {
          // User is marked as logged in locally (likely a phone user)
          DriverUserModel? driverModel =
              await FireStoreUtils.getDriverProfile(driverIdFromPrefs);

          if (driverModel != null) {
            FireStoreUtils.currentDriverUser = driverModel;
            AppLogger.info(
                "SplashController: Driver already logged in (phone). Navigating to Dashboard.",
                tag: "SplashController");
            Get.offAll(() => const DashBoardScreen());
            return;
          } else {
            AppLogger.warning(
                "SplashController: Inconsistent login state (phone). Driver data not found or invalid. Forcing logout and navigating to Login.",
                tag: "SplashController");
            await Preferences.clearDriverUserData();
            await Preferences.setBoolean(Constant.isLoggedInKey, false);
            Get.offAll(() => const LoginScreen());
            return;
          }
        } else {
          // Check Firebase Auth for social logins
          User? firebaseUser = FirebaseAuth.instance.currentUser;
          AppLogger.info(
              "SplashController: firebaseUser = ${firebaseUser?.uid}",
              tag: "SplashController");

          if (firebaseUser != null) {
            DriverUserModel? driverModel =
                await FireStoreUtils.getDriverProfile(firebaseUser.uid);

            if (driverModel != null) {
              FireStoreUtils.currentDriverUser = driverModel;
              await Preferences.saveDriverUserData(driverModel);
              await Preferences.setBoolean(Constant.isLoggedInKey, true);
              AppLogger.info(
                  "SplashController: Driver already logged in (social). Navigating to Dashboard.",
                  tag: "SplashController");
              Get.offAll(() => const DashBoardScreen());
              return;
            } else {
              AppLogger.warning(
                  "SplashController: Firebase Auth user found, but no Firestore profile. Navigating to InformationScreen.",
                  tag: "SplashController");
              DriverUserModel incompleteDriver = DriverUserModel(
                id: firebaseUser.uid,
                fullName: firebaseUser.displayName,
                email: firebaseUser.email,
                phoneNumber: firebaseUser.phoneNumber,
                profilePic: firebaseUser.photoURL ?? Constant.userPlaceHolder,
                loginType: firebaseUser.providerData.isNotEmpty
                    ? firebaseUser.providerData[0].providerId
                    : null,
                documentVerification: false,
                isOnline: false,
                createdAt: Timestamp.now(),
                walletAmount: "0.0",
                reviewsCount: "0.0",
                reviewsSum: "0.0",
                rotation: 0.0,
                zoneIds: [],
              );
              Get.offAll(() => InformationScreen(),
                  arguments: {'userModel': incompleteDriver});
              return;
            }
          } else {
            AppLogger.info(
                "SplashController: Driver not logged in. Navigating to Login Screen.",
                tag: "SplashController");
            Get.offAll(() => const LoginScreen());
            return;
          }
        }
      } else {
        AppLogger.info(
            "SplashController: Onboarding not finished. Navigating to OnBoarding Screen.",
            tag: "SplashController");
        Get.offAll(() => const OnBoardingScreen());
        return;
      }
    } catch (e, s) {
      AppLogger.error("SplashController: redirectScreen failed: $e",
          tag: "SplashController", error: e, stackTrace: s);
      navigationFailed.value = true;
    }
  }

  void retryRedirect() {
    AppLogger.info("SplashController: Retry redirect requested.",
        tag: "SplashController");
    navigationFailed.value = false;

    // Also delay retry to ensure Navigator is ready
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        redirectScreen();
      });
    });
  }
}
