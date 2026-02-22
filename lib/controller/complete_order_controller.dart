import 'package:driver/constant/constant.dart';
import 'package:driver/model/order_model.dart';
import 'package:get/get.dart';
import 'package:driver/utils/app_logger.dart';

class CompleteOrderController extends GetxController {
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    AppLogger.debug("CompleteOrderController onInit called.", tag: "CompleteOrderController");
    getArgument();
    super.onInit();
  }

  Rx<OrderModel> orderModel = OrderModel().obs;

  RxString couponAmount = "0.0".obs;

  double calculateAmount() {
    AppLogger.debug("calculateAmount called.", tag: "CompleteOrderController");
    RxString taxAmount = "0.0".obs;
    if (orderModel.value.taxList != null) {
      for (var element in orderModel.value.taxList!) {
        taxAmount.value = (double.parse(taxAmount.value) +
            Constant().calculateTax(amount: (double.parse(orderModel.value.finalRate.toString()) - double.parse(couponAmount.value.toString())).toString(), taxModel: element))
            .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
      }
    }
    final calculatedAmount = (double.parse(orderModel.value.finalRate.toString()) - double.parse(couponAmount.value.toString())) + double.parse(taxAmount.value);
    AppLogger.info("Calculated amount: $calculatedAmount", tag: "CompleteOrderController");
    return calculatedAmount;
  }

  Future<void> getArgument() async {
    AppLogger.debug("getArgument called.", tag: "CompleteOrderController");
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderModel.value = argumentData['orderModel'];
      AppLogger.info("OrderModel received in arguments: ${orderModel.value.id}", tag: "CompleteOrderController");

      if (orderModel.value.coupon != null) {
        if (orderModel.value.coupon?.code != null) {
          if (orderModel.value.coupon!.type == "fix") {
            couponAmount.value = orderModel.value.coupon!.amount.toString();
            AppLogger.info("Coupon type: fix, amount: ${couponAmount.value}", tag: "CompleteOrderController");
          } else {
            couponAmount.value =
                ((double.parse(orderModel.value.finalRate.toString()) * double.parse(orderModel.value.coupon!.amount.toString())) / 100).toString();
            AppLogger.info("Coupon type: percentage, amount: ${couponAmount.value}", tag: "CompleteOrderController");
          }
        }
      }
    } else {
      AppLogger.warning("No arguments received for CompleteOrderController.", tag: "CompleteOrderController");
    }
    isLoading.value = false;
    update();
    AppLogger.debug("CompleteOrderController isLoading set to false.", tag: "CompleteOrderController");
  }
}

