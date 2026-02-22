import 'package:driver/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver/utils/app_logger.dart'; //EDIT

class ActiveOrderController extends GetxController {
  HomeController homeController = Get.put(HomeController());
  final TextEditingController otpController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    AppLogger.debug("ActiveOrderController initialized.",
        tag: "ActiveOrderController");
  }

  @override
  void onClose() {
    AppLogger.debug("ActiveOrderController closing, disposing otpController.",
        tag: "ActiveOrderController");
    otpController.dispose();
    super.onClose();
  }
}
