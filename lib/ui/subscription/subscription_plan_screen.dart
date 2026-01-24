import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/subscription_controller.dart';
import 'package:driver/model/subscription_plan_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SubscriptionPlanScreen extends StatelessWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<SubscriptionController>(
      init: SubscriptionController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.getThem()
              ? AppColors.darkBackground
              : AppColors.background,
          body: controller.isLoading.value
              ? Constant.loader(context)
              : controller.subscriptionPlanList.isEmpty
                  ? Center(
                      child: Text(
                        "No subscription plans available".tr,
                        style: TextStyle(
                          color: themeChange.getThem()
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => controller.refreshData(),
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.subscriptionPlanList.length,
                        itemBuilder: (context, index) {
                          final plan = controller.subscriptionPlanList[index];
                          final bool isCommissionModel =
                              controller.isCommissionModelPlan(plan);
                          final bool hasActiveSub =
                              controller.hasActiveSubscription();

                          return SubscriptionPlanCard(
                            plan: plan,
                            isSelected:
                                controller.selectedSubscriptionPlan.value.id ==
                                    plan.id,
                            isActive:
                                controller.userModel.value.subscriptionPlanId ==
                                    plan.id,
                            isDark: themeChange.getThem(),
                            isCommissionModel: isCommissionModel,
                            hasActiveSubscription: hasActiveSub,
                            onSelect: () {
                              controller.selectPlan(plan);
                            },
                            onBuy: () {
                              // If user has active subscription and clicks on Commission Model
                              if (hasActiveSub && isCommissionModel) {
                                _showSwitchToCommissionDialog(
                                    context, controller, themeChange);
                                return;
                              }

                              // If user has active subscription and clicking on another plan
                              if (hasActiveSub && !isCommissionModel) {
                                // Show confirmation dialog for switching plans
                                _showSwitchPlanDialog(
                                    context, controller, themeChange, plan);
                                return;
                              }

                              controller.selectPlan(plan);
                              // Handle free plans directly
                              if ((plan.priceDouble ?? 0) == 0) {
                                controller.selectedPaymentMethod.value =
                                    'wallet';
                                controller.placeOrder();
                              } else {
                                // Show payment method selection
                                _showPaymentMethodDialog(
                                    context, controller, themeChange);
                              }
                            },
                          );
                        },
                      ),
                    ),
        );
      },
    );
  }

  /// Show confirmation dialog to switch to Commission Model
  void _showSwitchToCommissionDialog(BuildContext context,
      SubscriptionController controller, DarkThemeProvider themeChange) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeChange.getThem()
              ? AppColors.darkContainerBackground
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Switch to Commission Model".tr,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeChange.getThem() ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            "Are you sure you want to cancel your current subscription and switch to the Commission Model? You will be charged admin commission on each ride."
                .tr,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: themeChange.getThem() ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                "Cancel".tr,
                style: GoogleFonts.poppins(
                  color: AppColors.subTitleColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Get.back();
                await controller.switchToCommissionModel();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Switch".tr,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show confirmation dialog to switch to another subscription plan
  void _showSwitchPlanDialog(
      BuildContext context,
      SubscriptionController controller,
      DarkThemeProvider themeChange,
      SubscriptionModel newPlan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeChange.getThem()
              ? AppColors.darkContainerBackground
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Switch Plan".tr,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeChange.getThem() ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            "Are you sure you want to switch to ${newPlan.name}? Your current subscription will be replaced with the new plan."
                .tr,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: themeChange.getThem() ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                "Cancel".tr,
                style: GoogleFonts.poppins(
                  color: AppColors.subTitleColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                controller.selectPlan(newPlan);
                // Handle free plans directly
                if ((newPlan.priceDouble ?? 0) == 0) {
                  controller.selectedPaymentMethod.value = 'wallet';
                  controller.placeOrder();
                } else {
                  // Show payment method selection
                  _showPaymentMethodDialog(context, controller, themeChange);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Switch".tr,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show payment method selection dialog
  void _showPaymentMethodDialog(BuildContext context,
      SubscriptionController controller, DarkThemeProvider themeChange) {
    final walletAmount =
        double.tryParse(controller.userModel.value.walletAmount ?? '0') ?? 0.0;
    final canPayWithWallet = walletAmount >= controller.totalAmount.value;

    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          topLeft: Radius.circular(30),
        ),
      ),
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Select Payment Method".tr,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color:
                          themeChange.getThem() ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Plan Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeChange.getThem()
                      ? AppColors.darkContainerBackground
                      : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.selectedSubscriptionPlan.value.name ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            themeChange.getThem() ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Amount: ${Constant.amountShow(amount: controller.totalAmount.value.toString())}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.subTitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Wallet Payment Option
              if (canPayWithWallet)
                _buildPaymentOption(
                  context,
                  themeChange,
                  controller,
                  paymentName: 'wallet',
                  title: "Wallet".tr,
                  subtitle:
                      "Balance: ${Constant.amountShow(amount: walletAmount.toString())}",
                  icon: Icons.account_balance_wallet,
                  onTap: () {
                    controller.selectedPaymentMethod.value = 'wallet';
                    Get.back();
                    controller.placeOrder();
                  },
                ),

              // Razorpay Payment Option
              _buildPaymentOption(
                context,
                themeChange,
                controller,
                paymentName: 'razorpay',
                title: "Razorpay".tr,
                subtitle: "Pay with Razorpay",
                icon: Icons.payment,
                onTap: () {
                  controller.selectedPaymentMethod.value = 'razorpay';
                  Get.back();
                  controller.openRazorpayCheckout();
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption(
    BuildContext context,
    DarkThemeProvider themeChange,
    SubscriptionController controller, {
    required String paymentName,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = controller.selectedPaymentMethod.value == paymentName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : themeChange.getThem()
                      ? AppColors.darkContainerBorder
                      : AppColors.containerBorder,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? (themeChange.getThem()
                    ? AppColors.darkContainerBackground
                    : AppColors.lightGray)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeChange.getThem()
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.subTitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Radio(
                  value: paymentName,
                  groupValue: controller.selectedPaymentMethod.value,
                  activeColor: AppColors.primary,
                  onChanged: (value) => onTap(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* =======================================================================
   SUBSCRIPTION CARD
======================================================================== */

class SubscriptionPlanCard extends StatelessWidget {
  final SubscriptionModel plan;
  final bool isSelected;
  final bool isActive;
  final bool isDark;
  final bool isCommissionModel;
  final bool hasActiveSubscription;
  final VoidCallback onSelect;
  final VoidCallback onBuy;

  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.isActive,
    required this.isDark,
    this.isCommissionModel = false,
    this.hasActiveSubscription = false,
    required this.onSelect,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    // Define active colors that work well in both light and dark modes
    const activeBorderColor = Colors.green;
    final activeBackgroundColor =
        isDark ? Colors.green.withOpacity(0.1) : Colors.green.withOpacity(0.05);

    return InkWell(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? activeBackgroundColor
              : (isDark
                  ? AppColors.darkContainerBackground
                  : AppColors.containerBackground),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? activeBorderColor
                : (isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkContainerBorder
                        : AppColors.containerBorder)),
            width: isActive ? 2.0 : 1.4,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeBorderColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// PLAN NAME
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.name ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                if (isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: activeBorderColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Activated".tr,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            /// DESCRIPTION
            Text(
              plan.description ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.subTitleColor,
              ),
            ),

            const SizedBox(height: 14),

            /// PRICE
            Text(
              (plan.priceDouble ?? 0) == 0
                  ? "Free".tr
                  : Constant.amountShow(amount: plan.price ?? '0'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.lightBlue,
              ),
            ),

            const SizedBox(height: 4),

            /// VALIDITY
            Text(
              _validityText(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.subTitleColor,
              ),
            ),

            const SizedBox(height: 16),

            /// BENEFITS FROM FIRESTORE
            ...(plan.planPoints ?? []).map(
              (point) => _benefitRow(point),
            ),

            const SizedBox(height: 20),

            /// ACTION BUTTON
            SizedBox(
              width: double.infinity,
              child: RoundedButtonFill(
                radius: 14,
                title: _getButtonTitle(),
                color: _getButtonColor(),
                textColor: Colors.white,
                onPress: isActive ? () {} : onBuy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 GET BUTTON TITLE
  String _getButtonTitle() {
    if (isActive) {
      return "Current Plan".tr;
    }
    // If user has active subscription and this is Commission Model, show "Switch"
    if (hasActiveSubscription && isCommissionModel) {
      return "Switch".tr;
    }
    // For free plans (including Commission Model when no active subscription)
    if ((plan.priceDouble ?? 0) == 0) {
      return "Activate".tr;
    }
    return "Buy Now".tr;
  }

  /// 🔹 GET BUTTON COLOR
  Color _getButtonColor() {
    if (isActive) {
      return Colors.grey.shade400;
    }
    // Orange color for switching to Commission Model
    if (hasActiveSubscription && isCommissionModel) {
      return Colors.orange;
    }
    return AppColors.primary;
  }

  /// 🔹 VALIDITY TEXT
  String _validityText() {
    if (plan.expiryType == 'monthly') {
      return "Valid for ${plan.expiryDay} days".tr;
    } else if (plan.expiryType == 'yearly') {
      return "Valid for 365 days".tr;
    }
    return "Lifetime".tr;
  }

  Widget _benefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 18,
            color: AppColors.ratingColour,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text.tr,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoundedButtonFill extends StatelessWidget {
  final String title;
  final double? width;
  final double? height;
  final double? fontSizes;
  final double? radius;
  final Color? color;
  final Color? textColor;
  final Widget? icon;
  final bool? isRight;
  final Function()? onPress;

  const RoundedButtonFill({
    super.key,
    required this.title,
    this.height,
    required this.onPress,
    this.width,
    this.color,
    this.icon,
    this.fontSizes,
    this.textColor,
    this.isRight,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(radius ?? 200),
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        if (onPress != null) {
          onPress!();
        }
      },
      child: Container(
        width: Responsive.width(width ?? 100, context),
        height: Responsive.height(height ?? 6, context),
        decoration: BoxDecoration(
          color: color ?? AppColors.primary,
          borderRadius: BorderRadius.circular(radius ?? 200),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null && isRight == false) ...[
              icon!,
              const SizedBox(width: 6),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSizes ?? 14,
                fontWeight: FontWeight.w600,
                color: textColor ?? Colors.white,
              ),
            ),
            if (icon != null && isRight == true) ...[
              const SizedBox(width: 6),
              icon!,
            ],
          ],
        ),
      ),
    );
  }
}
