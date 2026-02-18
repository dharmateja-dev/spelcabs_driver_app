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
  StreamSubscription? _orderSubscription;

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
  RxBool isAcceptingRide = false.obs;
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
  void getOrder() {
    try {
      AppLogger.info("Starting getOrder() [Stream]...",
          tag: "IntercityController");

      // Cancel existing stream to prevent duplicates
      _orderSubscription?.cancel();

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

      // Build query
      Query query = FireStoreUtils.fireStore
          .collection(CollectionName.ordersIntercity)
          .where('status', isEqualTo: Constant.ridePlaced);

      if (whenController.value.text.isNotEmpty && dateAndTime != null) {
        final formattedDate = DateFormat("dd-MMM-yyyy").format(dateAndTime!);
        query = query.where('whenDates', isEqualTo: formattedDate);
        AppLogger.debug("Date filter added: $formattedDate",
            tag: "IntercityController");
      }

      // Start Listening
      _orderSubscription = query.snapshots().listen((querySnapshot) {
        AppLogger.info(
            "Stream update: ${querySnapshot.docs.length} docs found.",
            tag: "IntercityController");

        const freightServiceId = Constant.freightServiceId;
        List<InterCityOrderModel> tempOrders = [];
        int kept = 0;

        for (var doc in querySnapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;

            // EXCLUDE freight orders
            final serviceId = data['intercityServiceId'] as String?;
            if (serviceId == freightServiceId) {
              continue; // Skip freight orders
            }

            // Client-side zone filtering
            final orderZoneId = data['zoneId'];
            if (driverModel.value.zoneIds != null &&
                driverModel.value.zoneIds!.isNotEmpty) {
              if (orderZoneId == null ||
                  !driverModel.value.zoneIds!.contains(orderZoneId)) {
                continue;
              }
            }

            // Client-side SOURCE match
            bool sourceOk = true;
            if (srcText.isNotEmpty) {
              sourceOk = eqOrContains(
                      data['sourceLocationName'] as String?, srcText) ||
                  eqOrContains(data['sourceName_norm'] as String?, srcText);
            }

            // Client-side DESTINATION match
            bool destOk = true;
            if (dstText.isNotEmpty) {
              destOk = eqOrContains(
                      data['destinationLocationName'] as String?, dstText) ||
                  eqOrContains(
                      data['destinationName_norm'] as String?, dstText);
            }

            if (!(sourceOk && destOk)) continue;

            final orderModel = InterCityOrderModel.fromJson(data);

            // Check if accepted by Current Driver (hide from New Orders only if YOU accepted/bid)
            if (orderModel.acceptedDriverId != null &&
                orderModel.acceptedDriverId!
                    .contains(FireStoreUtils.getCurrentUid())) {
              continue;
            }

            // Determin if the driver is a "Freight Driver" based on active services
            bool isFreightDriver = false;
            if (driverModel.value.activeServices != null &&
                driverModel.value.activeServices!
                    .containsKey(Constant.freightServiceId) &&
                driverModel.value.activeServices![Constant.freightServiceId] ==
                    true) {
              isFreightDriver = true;
            } else if (driverModel.value.serviceId ==
                Constant.freightServiceId) {
              isFreightDriver = true;
            }

            // STRICT RULE 1: Freight Drivers should ONLY see Freight Orders.
            // Since we already skipped Freight orders at the top of this loop (line 124),
            // any order reaching here is a PASSENGER Intercity Order.
            // Therefore, if the driver is a FREIGHT driver, they must NOT see this order.
            if (isFreightDriver) {
              continue;
            }

            // STRICT RULE 2: Service Drivers (Non-Freight) should catch ALL Passenger Intercity Orders.
            // The previous check required strict service ID matching (e.g., driver must have 's_shared' enabled).
            // The new requirement is: "all types of drivers who registered with service vehicle" should get these rides.
            // So if they are NOT a freight driver (and have active services), we show the order.

            // Ensure active services is not null just in case
            if (driverModel.value.activeServices == null) {
              continue;
            }

            tempOrders.add(orderModel);
            kept++;
          } catch (e, s) {
            AppLogger.error("Error parsing order document ${doc.id}: $e",
                tag: "IntercityController", error: e, stackTrace: s);
          }
        }

        // Sort by creation time (Newest First)
        tempOrders.sort((a, b) {
          final aTime = a.createdDate;
          final bTime = b.createdDate;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        intercityServiceOrder.assignAll(tempOrders);
        isLoading.value = false;
        AppLogger.info("Final display list updated: $kept orders (sorted).",
            tag: "IntercityController");
      }, onError: (e) {
        AppLogger.error("Stream error: $e", tag: "IntercityController");
        isLoading.value = false;
      });
    } catch (e, s) {
      AppLogger.error("Error setting up stream: $e",
          tag: "IntercityController", error: e, stackTrace: s);
      isLoading.value = false;
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
    _orderSubscription?.cancel();
    sourceCityController.value.dispose();
    destinationCityController.value.dispose();
    whenController.value.dispose();
    suggestedTimeController.value.dispose();
    enterOfferRateController.value.dispose();
    super.onClose();
  }
}
