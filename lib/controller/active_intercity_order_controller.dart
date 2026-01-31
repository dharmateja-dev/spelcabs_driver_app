import 'package:driver/controller/freight_controller.dart';
import 'package:driver/controller/home_intercity_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ActiveInterCityOrderController extends GetxController {
  HomeIntercityController homeController = Get.put(HomeIntercityController());
  FreightController frightController = Get.put(FreightController());
  final TextEditingController otpController = TextEditingController();

  @override
  void onClose() {
    otpController.dispose();
    super.onClose();
  }
}
