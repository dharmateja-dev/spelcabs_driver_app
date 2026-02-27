import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/ui/account_deletion_policy_scree.dart';
import 'package:driver/ui/auth_screen/login_screen.dart';
import 'package:driver/ui/bank_details/bank_details_screen.dart';
import 'package:driver/ui/chat_screen/inbox_screen.dart';
import 'package:driver/ui/contact_us/contact_us.dart';
import 'package:driver/ui/freight/freight_screen.dart';
import 'package:driver/ui/home_screens/home_screen.dart';
import 'package:driver/ui/intercity_screen/home_intercity_screen.dart';
import 'package:driver/ui/online_registration/online_registartion_screen.dart';
import 'package:driver/ui/privacy_policy_screen/privacy_policy_screen.dart';
import 'package:driver/ui/profile_screen/profile_screen.dart';
import 'package:driver/ui/settings_screen/setting_screen.dart';
import 'package:driver/ui/subscription/subscription_plan_screen.dart';
import 'package:driver/ui/vehicle_information/vehicle_information_screen.dart';
import 'package:driver/ui/wallet/wallet_screen.dart';
import 'package:driver/ui/terms_and_condition/terms_and_condition_screen.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class DashBoardController extends GetxController {
  /// Static variable to pass initial drawer index before navigation.
  /// Set this before calling Get.offAll to DashBoardScreen.
  /// It will be consumed (reset to null) in onInit.
  static int? pendingInitialIndex;

  final drawerItems = [
    DrawerItem('City'.tr, "assets/icons/ic_city.svg"),
    DrawerItem('Outstation'.tr, "assets/icons/ic_intercity.svg"),
    DrawerItem('Freight'.tr, "assets/icons/ic_freight.svg"),
    DrawerItem('My Wallet'.tr, "assets/icons/ic_wallet.svg"),
    DrawerItem('Bank Details'.tr, "assets/icons/ic_profile.svg"),
    DrawerItem('Inbox'.tr, "assets/icons/ic_inbox.svg"),
    DrawerItem('Profile'.tr, "assets/icons/ic_profile.svg"),
    DrawerItem('Online Registration'.tr, "assets/icons/ic_document.svg"),
    DrawerItem('Vehicle Information'.tr, "assets/icons/ic_city.svg"),
    DrawerItem('Settings'.tr, "assets/icons/ic_settings.svg"),
    DrawerItem('Terms & Conditions'.tr, "assets/icons/ic_terms.svg"),
    DrawerItem('Privacy Policy'.tr, "assets/icons/ic_terms.svg"),
    DrawerItem('Account Deletion'.tr, "assets/icons/ic_delete.svg"),
    DrawerItem('Support'.tr, "assets/icons/ic_contact_us.svg"),
    DrawerItem('Subscription'.tr, "assets/icons/ic_payment.svg"),
    DrawerItem('Log out'.tr, "assets/icons/ic_logout.svg"),
  ];

  StatelessWidget getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return const HomeScreen(); // City
      case 1:
        return const HomeIntercityScreen(); // OutStation
      case 2:
        return const FreightScreen(); // Freight
      case 3:
        return const WalletScreen(); // My Wallet
      case 4:
        return const BankDetailsScreen(); // Bank Details
      case 5:
        return const InboxScreen(); // Inbox
      case 6:
        return const ProfileScreen(); // Profile
      case 7:
        return const OnlineRegistrationScreen(); // Online Registration
      case 8:
        return const VehicleInformationScreen(); // Vehicle Information
      case 9:
        return const SettingScreen(); // Settings
      case 10:
        return const TermsAndConditionScreen(); // Terms & Conditions
      case 11:
        return const DriverPrivacyPolicyScreen(); // Privacy Policy
      case 12:
        return const AccountDeletionPolicyScreen(); // Account Deletion
      case 13:
        return const ContactUsScreen(); //contact us
      case 14:
        return const SubscriptionPlanScreen();
      default:
        return Text("Error".tr);
    }
  }

  RxInt selectedDrawerIndex = 0.obs;

  Future<void> onSelectItem(int index) async {
    if (index == 15) {
      // Logout index - check for active rides first
      ShowToastDialog.showLoader("Please wait".tr);
      bool hasActive = await FireStoreUtils.hasActiveRide();
      ShowToastDialog.closeLoader();

      if (hasActive) {
        ShowToastDialog.showToast(
            "You cannot logout while you have an active ride. Please complete or cancel your ride first."
                .tr);
        Get.back(); // Close drawer
        return;
      }

      // Proceed with logout
      FireStoreUtils.logout();
      await FirebaseAuth.instance.signOut();
      Get.offAll(const LoginScreen());
    } else {
      selectedDrawerIndex.value = index;
    }
    Get.back();
  }

  /// Subscription to monitor driver document deletion from admin panel
  StreamSubscription? _driverDocSubscription;
  bool _isRedirecting = false;

  @override
  void onInit() {
    // Check for pending initial index (set before navigation)
    if (pendingInitialIndex != null) {
      selectedDrawerIndex.value = pendingInitialIndex!;
      pendingInitialIndex = null; // Consume it
    }
    // Also check Get.arguments as fallback
    else if (Get.arguments != null &&
        Get.arguments is Map &&
        Get.arguments['initialIndex'] != null) {
      selectedDrawerIndex.value = Get.arguments['initialIndex'];
    }
    getLocation();
    _listenForAccountDeletion();
    super.onInit();
  }

  /// Listens to the driver's Firestore document.
  /// If the document is deleted (e.g., from admin panel), the driver is
  /// signed out and redirected to the login screen.
  void _listenForAccountDeletion() {
    final uid = FireStoreUtils.getCurrentUid();
    _driverDocSubscription = FirebaseFirestore.instance
        .collection(CollectionName.driverUsers)
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists && !_isRedirecting) {
        _isRedirecting = true;
        _handleAccountDeleted();
      }
    });
  }

  /// Signs out the user and redirects to login when account is deleted from admin
  Future<void> _handleAccountDeleted() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    ShowToastDialog.showToast("Your account has been deleted by the admin".tr);
    Get.offAll(const LoginScreen());
  }

  Future<void> getLocation() async {
    await Utils.determinePosition();
  }

  Rx<DateTime> currentBackPressTime = DateTime.now().obs;

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (now.difference(currentBackPressTime.value) >
        const Duration(seconds: 2)) {
      currentBackPressTime.value = now;
      ShowToastDialog.showToast("Double press to exit".tr,
          position: EasyLoadingToastPosition.center);
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  void onClose() {
    _driverDocSubscription?.cancel();
    super.onClose();
  }
}

class DrawerItem {
  String title;
  String icon;

  DrawerItem(this.title, this.icon);
}
