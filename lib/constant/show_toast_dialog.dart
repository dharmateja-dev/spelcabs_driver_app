import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class ShowToastDialog {
  static void showToast(String? message,
      {EasyLoadingToastPosition position = EasyLoadingToastPosition.top,
      Duration? duration}) {
    bool isDarkMode = Get.context != null &&
        (Theme.of(Get.context!).brightness == Brightness.dark);
    EasyLoading.instance.textColor = isDarkMode ? Colors.white : Colors.black;
    EasyLoading.showToast(message!,
        toastPosition: position, duration: duration);
  }

  static void showLoader(String message) {
    EasyLoading.show(status: message);
  }

  static void closeLoader() {
    EasyLoading.dismiss();
  }
}
