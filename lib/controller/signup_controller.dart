import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/utils/validation_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver/utils/app_logger.dart';
import 'package:driver/services/auth_apis.dart'; // Ensure this path is correct

class SignupController extends GetxController {
  Rx<TextEditingController> fullNameController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> phoneNumberController = TextEditingController().obs;
  RxString countryCode = "+91".obs;

  Rx<GlobalKey<FormState>> formKey = GlobalKey<FormState>().obs;

  // Validation error states - only set when user clicks the button
  RxnString emailError = RxnString(null);
  RxnString phoneError = RxnString(null);

  /// Validates the email and sets the error state.
  /// Returns true if valid, false otherwise.
  bool validateEmail() {
    final error = ValidationUtils.validateEmail(emailController.value.text);
    emailError.value = error;
    return error == null;
  }

  /// Validates the phone number and sets the error state.
  /// Returns true if valid, false otherwise.
  bool validatePhone() {
    final error =
        ValidationUtils.validatePhone(phoneNumberController.value.text);
    phoneError.value = error;
    return error == null;
  }

  /// Validates all fields and returns true if all are valid.
  bool validateAll() {
    final isEmailValid = validateEmail();
    final isPhoneValid = validatePhone();
    return isEmailValid && isPhoneValid;
  }

  /// Clears all validation errors.
  void clearErrors() {
    emailError.value = null;
    phoneError.value = null;
  }

  Future<void> validateAndSignup() async {
    AppLogger.info("SignupController: Initiating validateAndSignup.",
        tag: "SignupController");

    // Validate email and phone on button press
    if (!validateAll()) {
      return; // Stop if validation fails
    }

    if (formKey.value.currentState?.validate() ?? false) {
      if (fullNameController.value.text.isEmpty) {
        ShowToastDialog.showToast("Please enter your full name".tr);
        return;
      }
      // Email validation is now handled by validateAll()
      // Phone validation is now handled by validateAll()

      await AuthApiService.signupWithOtp(
        fullNameController.value.text,
        countryCode.value, // Pass country code separately
        phoneNumberController.value.text, // Pass local phone number
        emailController.value.text,
        Get.context!,
      );
    }
  }

  // Method to handle Google Sign-up (delegates to AuthApiService)
  Future<void> signInWithGoogle() async {
    AppLogger.info("SignupController: Initiating Google Sign-up.",
        tag: "SignupController");
    await AuthApiService.googleSignIn(Get.context!);
  }

  // Method to handle Apple Sign-up (delegates to AuthApiService)
  Future<void> signInWithApple() async {
    AppLogger.info("SignupController: Initiating Apple Sign-up.",
        tag: "SignupController");
    await AuthApiService.appleSignIn(Get.context!);
  }

  // Utility methods (if still needed)
  // String generateNonce([int length = 32]) {
  //   final charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  //   final random = Random.secure();
  //   return List.generate(length, (_) => charset[random.nextInt(charset.length)])
  //       .join();
  // }
  //
  // String sha256ofString(String input) {
  //   final bytes = utf8.encode(input);
  //   final digest = sha256.convert(bytes);
  //   return digest.toString();
  // }
}
