import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/ui/auth_screen/otp_screen.dart';
import 'package:driver/utils/validation_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:driver/utils/app_logger.dart';
import 'package:driver/services/auth_apis.dart'; // Ensure this path is correct

class LoginController extends GetxController {
  Rx<TextEditingController> phoneNumberController = TextEditingController().obs;
  RxString countryCode = "+91".obs;

  Rx<GlobalKey<FormState>> formKey = GlobalKey<FormState>().obs;

  // Validation error state - only set when user clicks the button
  RxnString phoneError = RxnString(null);

  /// Validates the phone number and sets the error state.
  /// Returns true if valid, false otherwise.
  bool validatePhone() {
    final error =
        ValidationUtils.validatePhone(phoneNumberController.value.text);
    phoneError.value = error;
    return error == null;
  }

  /// Clears the phone validation error.
  void clearPhoneError() {
    phoneError.value = null;
  }

  // sendCode() is now refactored to use AuthApiService.loginWithOtp
  sendCode() async {
    AppLogger.info("LoginController: Initiating sendCode for phone login.",
        tag: "LoginController");

    // Validate on button press
    if (!validatePhone()) {
      return; // Stop if validation fails
    }

    if (formKey.value.currentState!.validate()) {
      await AuthApiService.loginWithOtp(
        countryCode.value,
        phoneNumberController.value.text, // Pass full phone number
        Get.context!,
      );
    }
  }

  // Method to handle Google Sign-in
  Future<void> signInWithGoogle() async {
    AppLogger.info("LoginController: Initiating Google Sign-in.",
        tag: "LoginController");
    await AuthApiService.googleSignIn(Get.context!);
  }

  // Method to handle Apple Sign-in
  Future<void> signInWithApple() async {
    AppLogger.info("LoginController: Initiating Apple Sign-in.",
        tag: "LoginController");
    await AuthApiService.appleSignIn(Get.context!);
  }

  // Utility methods (if still needed, e.g., for password-based auth, though not directly used here)
  // String generateNonce([int length = 32]) {
  //   final charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  //   final random = Random.secure();
  //   return List.generate(length, (_) => charset[random.nextInt(charset.length)])
  //       .join();
  // }

  // String sha256ofString(String input) {
  //   final bytes = utf8.encode(input);
  //   final digest = sha256.convert(bytes);
  //   return digest.toString();
  // }
}
