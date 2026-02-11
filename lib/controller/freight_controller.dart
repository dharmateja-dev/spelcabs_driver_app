import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/controller/dash_board_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/intercity_order_model.dart';
import 'package:driver/model/order/location_lat_lng.dart';
import 'package:driver/model/order/positions.dart';
import 'package:driver/ui/freight/accepted_freight_orders.dart';
import 'package:driver/ui/freight/active_freight_order_screen.dart';
import 'package:driver/ui/freight/new_orders_freight_screen.dart';
import 'package:driver/ui/freight/order_freight_screen.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:driver/widget/geoflutterfire/src/models/point.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'package:driver/utils/location_permission_helper.dart';

class FreightController extends GetxController {
  RxInt selectedIndex = 0.obs;
  List<Widget> widgetOptions = <Widget>[
    const NewOrderFreightScreen(),
    const AcceptedFreightOrders(),
    const ActiveFreightOrderScreen(),
    const OrderFreightScreen()
  ];
  DashBoardController dashboardController = Get.put(DashBoardController());

  /// Stream subscriptions for proper cleanup
  StreamSubscription? _driverSubscription;
  StreamSubscription? _freightSubscription;
  StreamSubscription? _activeRideSubscription;
  StreamSubscription? _locationSubscription;

  Rx<TextEditingController> whenController = TextEditingController().obs;
  Rx<TextEditingController> suggestedTimeController =
      TextEditingController().obs;
  DateTime? suggestedTime = DateTime.now();
  DateTime? dateAndTime = DateTime.now();
  RxString newAmount = "0.0".obs;
  Rx<TextEditingController> enterOfferRateController =
      TextEditingController().obs;

  // Search functionality
  Rx<TextEditingController> sourceCityController = TextEditingController().obs;
  Rx<TextEditingController> destinationCityController =
      TextEditingController().obs;
  RxList<InterCityOrderModel> freightServiceOrder = <InterCityOrderModel>[].obs;
  RxBool isSearchLoading = false.obs;

  void clearSearch() {
    sourceCityController.value.clear();
    destinationCityController.value.clear();
    whenController.value.clear();
    freightServiceOrder.clear();
    dateAndTime = DateTime.now();
  }

  void searchFreightOrders() {
    try {
      print("🔍 [FREIGHT] Starting freight search [Stream]...");

      _freightSubscription?.cancel();

      isSearchLoading.value = true;
      freightServiceOrder.clear();

      final srcText = sourceCityController.value.text.trim();
      final dstText = destinationCityController.value.text.trim();

      print("🔍 [FREIGHT] Search criteria:");
      print("   - Source: '$srcText'");
      print("   - Destination: '$dstText'");
      print("   - Date: '${whenController.value.text}'");

      // Helper function for lenient matching
      String norm(String s) => s.trim().toLowerCase();
      bool eqOrContains(String? haystack, String needle) {
        if (haystack == null) return false;
        final h = norm(haystack);
        final n = norm(needle);
        return h == n || h.contains(n);
      }

      // Build query
      Query query = FireStoreUtils.fireStore
          .collection(CollectionName.ordersIntercity)
          .where('status', isEqualTo: Constant.ridePlaced)
          .where('intercityServiceId', isEqualTo: Constant.freightServiceId);

      // Add date filter
      if (whenController.value.text.isNotEmpty && dateAndTime != null) {
        String formattedDate = DateFormat("dd-MMM-yyyy").format(dateAndTime!);
        query = query.where('whenDates', isEqualTo: formattedDate);
        print("🔍 [FREIGHT] Date filter: $formattedDate");
      }

      // Start Listening
      _freightSubscription = query.snapshots().listen((querySnapshot) {
        print(
            "🔍 [FREIGHT] Stream update: ${querySnapshot.docs.length} docs found.");

        int kept = 0;
        List<InterCityOrderModel> tempOrders = [];

        for (var doc in querySnapshot.docs) {
          try {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            // Zone filtering (client side if needed, or if query didn't handle it)
            final orderZoneId = data['zoneId'];
            if (driverModel.value.zoneIds != null &&
                driverModel.value.zoneIds!.isNotEmpty) {
              if (orderZoneId == null ||
                  !driverModel.value.zoneIds!.contains(orderZoneId)) {
                continue;
              }
            }

            // Client-side Source match
            bool sourceOk = true;
            if (srcText.isNotEmpty) {
              sourceOk = eqOrContains(
                      data['sourceLocationName'] as String?, srcText) ||
                  eqOrContains(data['sourceName_norm'] as String?, srcText);
            }

            // Client-side Destination match
            bool destOk = true;
            if (dstText.isNotEmpty) {
              destOk = eqOrContains(
                      data['destinationLocationName'] as String?, dstText) ||
                  eqOrContains(
                      data['destinationName_norm'] as String?, dstText);
            }

            if (!(sourceOk && destOk)) {
              continue;
            }

            InterCityOrderModel orderModel = InterCityOrderModel.fromJson(data);

            // Check if accepted by ANYONE (hide from New Orders)
            if (orderModel.acceptedDriverId != null &&
                orderModel.acceptedDriverId!.isNotEmpty) {
              continue;
            }

            // Check Vehicle Type Eligibility
            // Only drivers with the registered freight vehicle type should see freight orders.
            if (orderModel.freightVehicle != null &&
                driverModel.value.vehicleInformation != null) {
              if (driverModel.value.vehicleInformation!.vehicleTypeId !=
                  orderModel.freightVehicle!.id) {
                continue;
              }
            }

            tempOrders.add(orderModel);
            kept++;
          } catch (e) {
            print("   ❌ Error parsing order document ${doc.id}: $e");
          }
        }

        freightServiceOrder.assignAll(tempOrders);
        isSearchLoading.value = false;
        print("🔍 [FREIGHT] Final result: $kept freight orders displayed");
      }, onError: (e) {
        print("❌ [FREIGHT] Stream error: $e");
        isSearchLoading.value = false;
      });
    } catch (e) {
      print("❌ [FREIGHT] Error setting up stream: $e");
      isSearchLoading.value = false;
    }
  }

  void onItemTapped(int index) {
    selectedIndex.value = index;
  }

  @override
  void onInit() {
    getDriver();
    getActiveRide();
    super.onInit();
  }

  Rx<DriverUserModel> driverModel = DriverUserModel().obs;
  RxBool isLoading = true.obs;

  Future<void> getDriver() async {
    updateCurrentLocation();
    _driverSubscription = FireStoreUtils.fireStore
        .collection(CollectionName.driverUsers)
        .doc(FireStoreUtils.getCurrentUid())
        .snapshots()
        .listen((event) {
      if (event.exists) {
        driverModel.value = DriverUserModel.fromJson(event.data()!);
      }
    });
  }

  RxInt isActiveValue = 0.obs;

  void getActiveRide() {
    _activeRideSubscription = FirebaseFirestore.instance
        .collection(CollectionName.orders)
        .where('driverId', isEqualTo: FireStoreUtils.getCurrentUid())
        .where('status',
            whereIn: [Constant.rideInProgress, Constant.rideActive])
        .snapshots()
        .listen((event) {
          isActiveValue.value = event.size;
        });
  }

  Location location = Location();

  Future<void> updateCurrentLocation() async {
    // Use the new LocationPermissionHelper
    final hasPermission =
        await LocationPermissionHelper.checkAndRequestLocationPermission(
      showEducationalDialog: true,
    );

    if (!hasPermission) {
      isLoading.value = false;
      update();
      return;
    }

    // Request background location permission for drivers
    final hasBackgroundPermission =
        await LocationPermissionHelper.requestBackgroundLocationPermission();
    if (!hasBackgroundPermission) {
      // Continue anyway - app can work with "While Using" permission
    }

    // Permission granted, set up location tracking
    location.enableBackgroundMode(enable: true);
    location.changeSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: double.parse(Constant.driverLocationUpdate.toString()),
        interval: 2000);

    _locationSubscription = location.onLocationChanged.listen((locationData) {
      print("------>");
      print(locationData);
      Constant.currentLocation = LocationLatLng(
          latitude: locationData.latitude, longitude: locationData.longitude);
      FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid())
          .then((value) {
        DriverUserModel driverUserModel = value!;
        if (driverUserModel.isOnline == true) {
          driverUserModel.location = LocationLatLng(
              latitude: locationData.latitude,
              longitude: locationData.longitude);
          GeoFirePoint position = Geoflutterfire().point(
              latitude: locationData.latitude!,
              longitude: locationData.longitude!);

          driverUserModel.position =
              Positions(geoPoint: position.geoPoint, geohash: position.hash);
          driverUserModel.rotation = locationData.heading;
          FireStoreUtils.updateDriverUser(driverUserModel);
        }
      });
    });

    isLoading.value = false;
    update();
  }

  @override
  void onClose() {
    _driverSubscription?.cancel();
    _freightSubscription?.cancel();
    _activeRideSubscription?.cancel();
    _locationSubscription?.cancel();
    sourceCityController.value.dispose();
    destinationCityController.value.dispose();
    whenController.value.dispose();
    suggestedTimeController.value.dispose();
    enterOfferRateController.value.dispose();
    super.onClose();
  }
}
