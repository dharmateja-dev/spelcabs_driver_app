import 'package:driver/model/payment_model.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class OrderController extends GetxController {
  @override
  void onInit() {
    getPayment();
    super.onInit();
  }

  Rx<PaymentModel> paymentModel = PaymentModel().obs;
  RxBool isLoading = true.obs;

  Future<void> getPayment() async {
    await FireStoreUtils().getPayment().then((value) {
      if (value != null) {
        paymentModel.value = value;
        isLoading.value = false;
      }
    });
  }
}
