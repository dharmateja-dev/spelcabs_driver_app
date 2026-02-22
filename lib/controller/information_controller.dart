import 'dart:developer';

import 'package:driver/constant/constant.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/utils/validation_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InformationController extends GetxController {
  Rx<TextEditingController> fullNameController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> phoneNumberController = TextEditingController().obs;
  RxString countryCode = "+91".obs;
  RxString loginType = "".obs;

  Rx<DriverUserModel> userModel = DriverUserModel().obs;

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
    // Only validate email if it's not a google login (where email is usually autofilled and read-only)
    // Or if it IS editable, we must validate.
    // Based on UI logic: enabled: controller.loginType.value == Constant.googleLoginType ? false : true
    // So if loginType != googleLoginType, we validate email.
    bool pValid = validatePhone();
    bool eValid = true;

    if (loginType.value != Constant.googleLoginType) {
      eValid = validateEmail();
    } else {
      // If it is google login, email might be empty if something went wrong, but usually it's prefilled.
      // If we want to ensure it's valid even if prefilled:
      if (emailController.value.text.isNotEmpty) {
        // Optional: validate even if read-only to be safe?
        // For now let's just assume read-only fields from Google are valid or acceptable.
      }
    }
    return pValid && eValid;
  }

  @override
  void onInit() {
    super.onInit();

    log("=== InformationController onInit ===");
    log("Arguments: ${Get.arguments}");

    // Get user data from arguments
    if (Get.arguments != null && Get.arguments['userModel'] != null) {
      userModel.value = Get.arguments['userModel'];

      log("User Model received: ${userModel.value.toJson()}");
      log("Email: ${userModel.value.email}");
      log("Full Name: ${userModel.value.fullName}");
      log("Login Type: ${userModel.value.loginType}");

      // Pre-fill form fields
      fullNameController.value.text = userModel.value.fullName ?? '';
      emailController.value.text = userModel.value.email ?? '';

      // Handle phone number
      String phoneWithCode = userModel.value.phoneNumber ?? '';
      String userCountryCode = userModel.value.countryCode ?? '+91';

      if (phoneWithCode.startsWith(userCountryCode)) {
        phoneNumberController.value.text =
            phoneWithCode.substring(userCountryCode.length).trim();
      } else if (phoneWithCode.startsWith('+')) {
        phoneNumberController.value.text =
            phoneWithCode.replaceFirst(RegExp(r'^\+\d+'), '').trim();
      } else {
        phoneNumberController.value.text = phoneWithCode;
      }

      countryCode.value = userCountryCode;
      loginType.value = userModel.value.loginType ?? '';

      log("Form populated - Email field: ${emailController.value.text}");
      log("Form populated - Name field: ${fullNameController.value.text}");
      log("Form populated - Login Type: ${loginType.value}");
    } else {
      log("No userModel found in arguments!");
    }
  }

  @override
  void onClose() {
    fullNameController.value.dispose();
    emailController.value.dispose();
    phoneNumberController.value.dispose();
    super.onClose();
  }
}
