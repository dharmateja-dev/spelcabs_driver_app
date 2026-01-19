import 'package:driver/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver/utils/app_logger.dart'; //EDIT

class ActiveOrderController extends GetxController {
  HomeController homeController = Get.put(HomeController());
  Rx<TextEditingController> otpController = TextEditingController().obs;

  @override
  void onInit() {
    super.onInit();
    AppLogger.debug("ActiveOrderController initialized.", tag: "ActiveOrderController");
  }
}

