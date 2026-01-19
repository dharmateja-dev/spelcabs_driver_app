import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/subscription_plan_model.dart';
import 'package:driver/model/subscription_history.dart';
import 'package:driver/model/wallet_transaction_model.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../constant/constant.dart';

enum PaymentGateway {
  wallet,
  stripe,
  paypal,
  razorpay,
  paystack,
  flutterWave,
  mercadoPago,
  paytm,
  midTrans,
  orangeMoney,
  xendit
}

class SubscriptionController extends GetxController {
  // -------------------- STATE --------------------
  RxBool isLoading = true.obs;

  Rx<DriverUserModel> userModel = DriverUserModel().obs;

  RxList<SubscriptionModel> subscriptionPlanList = <SubscriptionModel>[].obs;

  Rx<SubscriptionModel> selectedSubscriptionPlan = SubscriptionModel().obs;

  RxString selectedPaymentMethod = ''.obs;
  RxDouble totalAmount = 0.0.obs;

  final Razorpay razorPay = Razorpay();

  var plans;

  var selectedPlan;

  var activePlan;

  // -------------------- INIT --------------------
  @override
  void onInit() {
    super.onInit();
    getInitData();
  }

  Future<void> getInitData() async {
    isLoading.value = true;

    userModel.value =
        await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid()) ??
            DriverUserModel();

    await getSubscriptionPlans();

    isLoading.value = false;
  }

  // -------------------- PLANS --------------------
  Future<void> getSubscriptionPlans() async {
    final plans = await FireStoreUtils.getAllSubscriptionPlans();

    subscriptionPlanList.assignAll(
      plans.where((e) => e.isActive == true || e.isEnable == true).toList(),
    );

    if (subscriptionPlanList.isNotEmpty) {
      selectedSubscriptionPlan.value = subscriptionPlanList.first;
    }
  }

  // -------------------- VALIDATIONS --------------------
  bool hasActiveSubscription() {
    if (userModel.value.subscriptionExpiryDate == null) return false;
    return userModel.value.subscriptionExpiryDate!
        .toDate()
        .isAfter(DateTime.now());
  }

  bool isSamePlanAlreadyActive(String planId) {
    return hasActiveSubscription() &&
        userModel.value.subscriptionPlanId == planId;
  }

  int getPlanDuration(String? planType) {
    if (planType == 'yearly') return 365;
    return 30; // monthly
  }

  // -------------------- SELECT PLAN --------------------
  void selectPlan(SubscriptionModel plan) {
    if (plan.id != null && isSamePlanAlreadyActive(plan.id!)) {
      ShowToastDialog.showToast("You already have this plan active.".tr);
      return;
    }

    if (hasActiveSubscription()) {
      ShowToastDialog.showToast("You already have an active subscription.".tr);
      return;
    }

    selectedSubscriptionPlan.value = plan;
    totalAmount.value =
        plan.priceDouble ?? double.tryParse(plan.price ?? '0') ?? 0.0;
  }

  // -------------------- PAYMENT SUCCESS --------------------
  void onPaymentSuccess() {
    placeOrder();
  }

  // -------------------- PLACE ORDER --------------------
  Future<void> placeOrder() async {
    ShowToastDialog.showLoader("Please wait".tr);

    final plan = selectedSubscriptionPlan.value;
    final now = Timestamp.now();

    // Assign subscription to user
    userModel.value.subscriptionPlanId = plan.id;
    userModel.value.subscriptionPlan = plan;
    if (userModel.value.subscriptionPlan != null) {
      userModel.value.subscriptionPlan!.createdAt = now;
    }

    final int durationDays = getPlanDuration(plan.planType ?? plan.expiryType);

    userModel.value.subscriptionExpiryDate =
        Timestamp.fromDate(DateTime.now().add(Duration(days: durationDays)));

    // Enforce ZERO COMMISSION
    userModel.value.commission = 0;

    // Save subscription history
    SubscriptionHistoryModel history = SubscriptionHistoryModel(
      id: Constant.getUuid(),
      userId: userModel.value.id,
      subscriptionPlan: plan,
      paymentType: selectedPaymentMethod.value,
      createdAt: now,
      expiryDate: userModel.value.subscriptionExpiryDate,
    );

    await FireStoreUtils.setSubscriptionTransaction(history);

    // Wallet deduction
    if (selectedPaymentMethod.value == PaymentGateway.wallet.name) {
      await deductWalletAmount();
    }

    await FireStoreUtils.updateDriverUser(userModel.value);

    ShowToastDialog.closeLoader();

    ShowToastDialog.showToast(
      "Subscription activated successfully.".tr,
    );

    Get.offAllNamed('/dashboard');
  }

  // -------------------- WALLET --------------------
  Future<void> deductWalletAmount() async {
    final currentWalletAmount =
        double.tryParse(userModel.value.walletAmount ?? '0') ?? 0.0;
    final newWalletAmount = currentWalletAmount - totalAmount.value;

    WalletTransactionModel transaction = WalletTransactionModel(
      id: Constant.getUuid(),
      userId: userModel.value.id,
      amount: totalAmount.value.toString(),
      createdDate: Timestamp.now(),
      paymentType: PaymentGateway.wallet.name,
      note: "Subscription purchase".tr,
      orderType: "subscription",
      userType: "driver",
    );

    await FireStoreUtils.setWalletTransaction(transaction);

    userModel.value.walletAmount = newWalletAmount.toString();
  }

  // -------------------- COMMISSION CHECK --------------------
  double calculateCommission(double fare) {
    if (hasActiveSubscription()) return 0;
    return Constant.adminCommission?.calculate(fare) ?? 0;
  }

  // -------------------- RAZORPAY --------------------
  void openRazorpayCheckout() {
    var options = {
      'key': Constant.razorPayKey,
      'amount': (totalAmount.value * 100).toInt(),
      'name': 'Subscription',
      'currency': 'INR',
      'description': selectedSubscriptionPlan.value.name ?? 'Subscription Plan',
    };

    razorPay.open(options);

    razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
        (PaymentSuccessResponse response) {
      onPaymentSuccess();
    });

    razorPay.on(Razorpay.EVENT_PAYMENT_ERROR,
        (PaymentFailureResponse response) {
      ShowToastDialog.showToast("Payment Failed".tr);
    });
  }

  @override
  void onClose() {
    razorPay.clear();
    super.onClose();
  }
}
