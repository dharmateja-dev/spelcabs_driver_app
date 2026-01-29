import 'dart:async';

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
import 'package:driver/utils/app_logger.dart';

class IntercityController extends GetxController {
  HomeIntercityController homeController = Get.put(HomeIntercityController());

  /// Stream subscription for driver data - cancelled in onClose
  StreamSubscription? _driverSubscription;

  Rx<TextEditingController> sourceCityController = TextEditingController().obs;
  Rx<TextEditingController> destinationCityController =
      TextEditingController().obs;
  Rx<TextEditingController> whenController = TextEditingController().obs;
  Rx<TextEditingController> suggestedTimeController =
      TextEditingController().obs;
  DateTime? suggestedTime = DateTime.now();
  DateTime? dateAndTime = DateTime.now();

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
      _driverSubscription = FireStoreUtils.fireStore
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

  /// Gets intercity orders - simplified version without zone validation.
  /// All orders matching basic criteria (status, date, zone) will be shown.
  getOrder() async {
    try {
      AppLogger.info("Starting getOrder() function...",
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

      // ---- Build a BROAD Firestore query (no exact text equals for locations) ----
      Query query = FireStoreUtils.fireStore
          .collection(CollectionName.ordersIntercity)
          .where('status', isEqualTo: Constant.ridePlaced);

      // keep your existing string date filter (your DB uses string field `whenDates`)
      if (whenController.value.text.isNotEmpty && dateAndTime != null) {
        final formattedDate = DateFormat("dd-MMM-yyyy").format(dateAndTime!);
        query = query.where('whenDates', isEqualTo: formattedDate);
        AppLogger.debug("Date filter added: $formattedDate",
            tag: "IntercityController");
      }

      if (driverModel.value.zoneIds != null &&
          driverModel.value.zoneIds!.isNotEmpty) {
        query = query.where('zoneId', whereIn: driverModel.value.zoneIds);
        AppLogger.debug("Zone filter added: ${driverModel.value.zoneIds}",
            tag: "IntercityController");
      }

      AppLogger.info("Executing Firestore query (broad)…",
          tag: "IntercityController");
      final querySnapshot = await query.get();
      AppLogger.info("Found ${querySnapshot.docs.length} orders (pre-filter).",
          tag: "IntercityController");

      final uid = FireStoreUtils.getCurrentUid();
      const freightServiceId =
          Constant.freightServiceId; // Freight service ID to EXCLUDE
      int kept = 0;

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // EXCLUDE freight orders - only show intercity orders
          final serviceId = data['intercityServiceId'] as String?;
          if (serviceId == freightServiceId) {
            AppLogger.debug(
                "Order ${doc.id} is a freight order; skipping for intercity list.",
                tag: "IntercityController");
            continue; // Skip freight orders
          }

          // ---- Client-side SOURCE match (lenient) ----
          bool sourceOk = true;
          if (srcText.isNotEmpty) {
            sourceOk =
                eqOrContains(data['sourceLocationName'] as String?, srcText) ||
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
            intercityServiceOrder.add(orderModel);
            kept++;
            AppLogger.debug("Order ${doc.id} kept after client filters.",
                tag: "IntercityController");
          } else {
            AppLogger.debug("Order ${doc.id} already accepted; skipping.",
                tag: "IntercityController");
          }
        } catch (e, s) {
          AppLogger.error("Error parsing order document ${doc.id}: $e",
              tag: "IntercityController", error: e, stackTrace: s);
        }
      }

      AppLogger.info("Final display list contains $kept orders.",
          tag: "IntercityController");
    } catch (e, s) {
      AppLogger.error("Error in getOrder: $e",
          tag: "IntercityController", error: e, stackTrace: s);
    } finally {
      isLoading.value = false;
      AppLogger.info("Finished getOrder() function.",
          tag: "IntercityController");
    }
  }

  void clearSearch() {
    AppLogger.info("Clearing search criteria.", tag: "IntercityController");
    sourceCityController.value.clear();
    destinationCityController.value.clear();
    whenController.value.clear();
    intercityServiceOrder.clear();
    dateAndTime = DateTime.now();
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
    _driverSubscription?.cancel();
    sourceCityController.value.dispose();
    destinationCityController.value.dispose();
    whenController.value.dispose();
    suggestedTimeController.value.dispose();
    enterOfferRateController.value.dispose();
    super.onClose();
  }
}
