import 'package:driver/constant/collection_name.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/utils/validation_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ContactUsController extends GetxController {
  RxBool isLoading = true.obs;

  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> feedbackController = TextEditingController().obs;

  @override
  void onInit() {
    getContactUsInformation();
    super.onInit();
  }

  RxString email = "".obs;
  RxString phone = "".obs;
  RxString address = "".obs;
  RxString subject = "".obs;

  // Validation error state
  RxnString emailError = RxnString(null);

  /// Validates the email and sets the error state.
  /// Returns true if valid, false otherwise.
  bool validateEmail() {
    final error = ValidationUtils.validateEmail(emailController.value.text);
    emailError.value = error;
    return error == null;
  }

  getContactUsInformation() async {
    await FireStoreUtils.fireStore
        .collection(CollectionName.settings)
        .doc("contact_us")
        .get()
        .then((value) {
      if (value.exists) {
        email.value = value.data()!["email"];
        phone.value = value.data()!["phone"];
        address.value = value.data()!["address"];
        subject.value = value.data()!["subject"];
        isLoading.value = false;
      }
    });
  }
}
