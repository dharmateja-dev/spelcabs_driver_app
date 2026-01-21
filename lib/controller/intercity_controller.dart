import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/controller/home_intercity_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/intercity_order_model.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:developer';

import 'dart:async'; // Added for StreamSubscription
import 'package:driver/utils/app_logger.dart';

class IntercityController extends GetxController {
  HomeIntercityController homeController = Get.put(HomeIntercityController());

  Rx<TextEditingController> sourceCityController = TextEditingController().obs;
  Rx<TextEditingController> destinationCityController =
      TextEditingController().obs;
  Rx<TextEditingController> whenController = TextEditingController().obs;
  Rx<TextEditingController> suggestedTimeController =
      TextEditingController().obs;
  DateTime? suggestedTime = DateTime.now();
  DateTime? dateAndTime = DateTime.now();
  StreamSubscription?
      _intercityOrderSubscription; // Subscription for real-time updates

  @override
  void onInit() {
    super.onInit();
    AppLogger.debug("IntercityController initialized.",
        tag: "IntercityController");
    _listenToDriverData();
  }

  RxList<InterCityOrderModel> intercityServiceOrder =
      <InterCityOrderModel>[].obs;
  RxBool isLoading = false.obs;
  RxString newAmount = "0.0".obs;
  Rx<TextEditingController> enterOfferRateController =
      TextEditingController().obs;
  Rx<DriverUserModel> driverModel = DriverUserModel().obs;

  void _listenToDriverData() {
    try {
      FireStoreUtils.fireStore
          .collection(CollectionName.driverUsers)
          .doc(FireStoreUtils.getCurrentUid())
          .snapshots()
          .listen((event) {
        if (event.exists && event.data() != null) {
          driverModel.value = DriverUserModel.fromJson(event.data()!);
          AppLogger.debug("Driver data updated: ${driverModel.value.id}",
              tag: "IntercityController");
        }
      });
    } catch (e) {
      AppLogger.error("Error listening to driver data: $e",
          tag: "IntercityController");
    }
  }

  getOrder() async {
    // Cancel any existing subscription to avoid duplicates
    await _intercityOrderSubscription?.cancel();
    _intercityOrderSubscription = null;

    try {
      AppLogger.info("Starting getOrder() function - Initializing Stream...",
          tag: "IntercityController");
      isLoading.value = true;
      intercityServiceOrder.clear();

      // helpers
      String norm(String s) => s.trim().toLowerCase();
      bool eqOrContains(String? haystack, String needle) {
        if (haystack == null) return false;
        final h = norm(haystack);
        final n = norm(needle);
        return h == n || h.contains(n);
      }

      final srcText = sourceCityController.value.text.trim();
      final dstText = destinationCityController.value.text.trim();

      AppLogger.info(
        'Search criteria -> Source: "$srcText", Destination: "$dstText", Date: "${whenController.value.text}"',
        tag: "IntercityController",
      );

      // ---- Build Firestore query for Outstation/Intercity rides ----
      Query query = FireStoreUtils.fireStore
          .collection(CollectionName.ordersIntercity)
          .where('status', isEqualTo: Constant.ridePlaced);

      // Date filter (if specified)
      if (whenController.value.text.isNotEmpty && dateAndTime != null) {
        final formattedDate = DateFormat("dd-MMM-yyyy").format(dateAndTime!);
        query = query.where('whenDates', isEqualTo: formattedDate);
        AppLogger.debug("Date filter added: $formattedDate",
            tag: "IntercityController");
      }

      // Zone-based filtering for Outstation rides
      if (driverModel.value.zoneIds != null &&
          driverModel.value.zoneIds!.isNotEmpty) {
        bool hasWorldwideZone = await FireStoreUtils.hasDriverWorldwideZone(
            driverModel.value.zoneIds);

        AppLogger.debug(
            "Driver zone check - Worldwide: $hasWorldwideZone. Showing ALL intercity orders per requirement (Outstation shows all cities).",
            tag: "IntercityController");
      } else {
        AppLogger.warning(
            "Driver has no zones assigned - showing all intercity orders",
            tag: "IntercityController");
      }

      AppLogger.info("Listening to Firestore query (broad)…",
          tag: "IntercityController");

      // Use snapshots() for real-time updates
      _intercityOrderSubscription = query.snapshots().listen((querySnapshot) {
        AppLogger.info(
            "Stream update received: ${querySnapshot.docs.length} orders (pre-filter).",
            tag: "IntercityController");

        final uid = FireStoreUtils.getCurrentUid();
        const freightServiceId =
            "Kn2VEnPI3ikF58uK8YqY"; // Freight service ID to EXCLUDE
        int kept = 0;
        List<InterCityOrderModel> tempOrders = [];

        for (var doc in querySnapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;

            // ✅ FIX: EXCLUDE freight orders - only show intercity orders
            final serviceId = data['intercityServiceId'] as String?;
            if (serviceId == freightServiceId) {
              continue; // Skip freight orders
            }

            // ---- Client-side SOURCE match (lenient) ----
            bool sourceOk = true;
            if (srcText.isNotEmpty) {
              sourceOk = eqOrContains(
                      data['sourceLocationName'] as String?, srcText) ||
                  eqOrContains(data['sourceName_norm'] as String?,
                      srcText); // ok if absent
            }

            // ---- Client-side DESTINATION match (lenient) ----
            bool destOk = true;
            if (dstText.isNotEmpty) {
              destOk = eqOrContains(
                      data['destinationLocationName'] as String?, dstText) ||
                  eqOrContains(data['destinationName_norm'] as String?,
                      dstText); // ok if absent
            }

            if (!(sourceOk && destOk)) continue;

            final orderModel = InterCityOrderModel.fromJson(data);

            // skip already accepted by this driver (your existing logic)
            bool alreadyAccepted = false;
            final accepted = orderModel.acceptedDriverId;
            if (accepted != null) {
              alreadyAccepted = accepted.cast<String>().contains(uid);
            }

            if (!alreadyAccepted) {
              tempOrders.add(orderModel);
              kept++;
            }
          } catch (e, s) {
            AppLogger.error("Error parsing order document ${doc.id}: $e",
                tag: "IntercityController", error: e, stackTrace: s);
          }
        }

        intercityServiceOrder.value = tempOrders;
        isLoading.value = false;
        AppLogger.info(
            "Final display list contains $kept orders (post-filter).",
            tag: "IntercityController");
      }, onError: (e) {
        AppLogger.error("Error in intercity order stream: $e",
            tag: "IntercityController");
        isLoading.value = false;
      });
    } catch (e, s) {
      AppLogger.error("Error setting up getOrder stream: $e",
          tag: "IntercityController", error: e, stackTrace: s);
      isLoading.value = false; // Ensure loading stops on setup error
    }
  }

  void clearSearch() {
    AppLogger.info("Clearing search criteria and cancelling stream.",
        tag: "IntercityController");
    sourceCityController.value.clear();
    destinationCityController.value.clear();
    whenController.value.clear();
    intercityServiceOrder.clear();
    dateAndTime = null;
    _intercityOrderSubscription?.cancel();
    _intercityOrderSubscription = null;
  }

  // ====== UPDATED: properly validate search criteria ======
  bool validateSearchCriteria() {
    AppLogger.debug("Validating search criteria.", tag: "IntercityController");

    // Check if source location is entered
    if (sourceCityController.value.text.trim().isEmpty) {
      AppLogger.debug(
          "Search criteria validation failed: source location is empty.",
          tag: "IntercityController");
      return false;
    }

    // Check if destination location is entered
    if (destinationCityController.value.text.trim().isEmpty) {
      AppLogger.debug(
          "Search criteria validation failed: destination location is empty.",
          tag: "IntercityController");
      return false;
    }

    AppLogger.debug("Search criteria validation passed.",
        tag: "IntercityController");
    return true;
  }
  // ==========================================================================

  @override
  void onClose() {
    AppLogger.info("IntercityController onClose called, disposing controllers.",
        tag: "IntercityController");
    _intercityOrderSubscription?.cancel();
    sourceCityController.value.dispose();
    destinationCityController.value.dispose();
    whenController.value.dispose();
    suggestedTimeController.value.dispose();
    enterOfferRateController.value.dispose();
    super.onClose();
  }
}
