import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver/utils/app_logger.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/services/auth_apis.dart';

class OtpController extends GetxController {
  TextEditingController otpController = TextEditingController();

  RxString countryCode = "".obs;
  RxString phoneNumber = "".obs;
  RxString verificationId = "".obs; // Firebase verification ID
  RxBool isSignup = false.obs; // To differentiate between login and signup flow
  RxString fullname = "".obs; // For signup flow
  RxString email = "".obs;

  @override
  void onInit() {
    AppLogger.info("OtpController: Initializing.", tag: "OtpController");
    getArgument();
    super.onInit();
  }

  getArgument() async {
    AppLogger.info("OtpController: Retrieving arguments.",
        tag: "OtpController");
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      countryCode.value = argumentData['countryCode'] ?? "";
      phoneNumber.value = argumentData['phoneNumber'] ?? "";
      verificationId.value =
          argumentData['verificationId'] ?? ""; // Firebase verificationId
      isSignup.value = argumentData['isSignup'] ?? false;
      fullname.value = argumentData['fullname'] ?? "";
      email.value = argumentData['email'] ?? "";

      AppLogger.debug(
        "OtpController: Arguments received - "
        "phoneNumber: ${phoneNumber.value}, "
        "verificationId: ${verificationId.value}, "
        "isSignup: ${isSignup.value}, "
        "fullname: ${fullname.value}, "
        "email: ${email.value}",
        tag: "OtpController",
      );
    } else {
      AppLogger.warning("OtpController: No arguments received.",
          tag: "OtpController");
    }
    update(); // Notify GetX listeners of state change
  }

  Future<void> verifyOtp() async {
    AppLogger.info("OtpController: Initiating OTP verification.",
        tag: "OtpController");

    if (otpController.text.isEmpty || otpController.text.length < 6) {
      ShowToastDialog.showToast("Please Enter Valid OTP".tr);
      return;
    }

    ShowToastDialog.showLoader("Verifying OTP...");

    // Unfocus keyboard to prevent interaction with disposed controller during navigation
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      // Create Firebase Phone Auth credential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: otpController.text,
      );

      // Sign in with Firebase credential
      await FirebaseAuth.instance.signInWithCredential(credential);

      AppLogger.info(
        "OtpController: Firebase OTP verification successful. Proceeding to complete login/signup.",
        tag: "OtpController",
      );

      // If Firebase verification is successful, proceed to complete login/signup logic
      if (isSignup.value) {
        // For signup, call the completeSignupWithOtp method in AuthApiService
        await AuthApiService.completeSignupWithOtp(
          fullname.value,
          countryCode.value,
          phoneNumber.value,
          email.value,
          Get.context!,
        );
      } else {
        // For login, call the completeLoginWithOtp method in AuthApiService
        AppLogger.debug(
          "Calling completeLoginWithOtp for ${countryCode.value}, ${phoneNumber.value}",
          tag: "OtpController",
        );
        await AuthApiService.completeLoginWithOtp(
          countryCode.value,
          phoneNumber.value,
          Get.context!,
        );
      }
    } on FirebaseAuthException catch (e) {
      ShowToastDialog.closeLoader();

      if (e.code == 'invalid-verification-code') {
        ShowToastDialog.showToast("Invalid OTP".tr);
        AppLogger.warning(
          "OtpController: Firebase OTP verification failed - Invalid code.",
          tag: "OtpController",
        );
      } else if (e.code == 'session-expired') {
        ShowToastDialog.showToast("OTP expired. Please request a new one.".tr);
        AppLogger.warning(
          "OtpController: Firebase OTP verification failed - Session expired.",
          tag: "OtpController",
        );
      } else {
        ShowToastDialog.showToast("Verification failed: ${e.message}");
        AppLogger.error(
          "OtpController: Firebase OTP verification failed",
          tag: "OtpController",
          error: e,
        );
      }
    } catch (e, s) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("An error occurred during verification".tr);
      AppLogger.error(
        "OtpController: Unexpected error during OTP verification",
        tag: "OtpController",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  void onClose() {
    otpController.dispose();
    super.onClose();
  }
}
