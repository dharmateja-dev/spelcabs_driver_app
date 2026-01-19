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

class FreightController extends GetxController {
  RxInt selectedIndex = 0.obs;
  List<Widget> widgetOptions = <Widget>[
    const NewOrderFreightScreen(),
    const AcceptedFreightOrders(),
    const ActiveFreightOrderScreen(),
    const OrderFreightScreen()
  ];
  DashBoardController dashboardController = Get.put(DashBoardController());

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

  Future<void> searchFreightOrders() async {
    try {
      print("🔍 [FREIGHT] Starting freight search...");
      isSearchLoading.value = true;
      freightServiceOrder.clear();

      final srcText = sourceCityController.value.text.trim();
      final dstText = destinationCityController.value.text.trim();

      print("🔍 [FREIGHT] Search criteria:");
      print("   - Source: '$srcText'");
      print("   - Destination: '$dstText'");
      print("   - Date: '${whenController.value.text}'");

      // Helper function for lenient matching
      String _norm(String s) => s.trim().toLowerCase();
      bool _eqOrContains(String? haystack, String needle) {
        if (haystack == null) return false;
        final h = _norm(haystack);
        final n = _norm(needle);
        return h == n || h.contains(n);
      }

      // ✅ Build a BROADER query - only filter by status and freight serviceId
      Query query = FireStoreUtils.fireStore
          .collection(CollectionName.ordersIntercity)
          .where('status', isEqualTo: Constant.ridePlaced)
          .where('intercityServiceId',
              isEqualTo: "Kn2VEnPI3ikF58uK8YqY"); // Freight filter

      // Add date filter if provided
      if (whenController.value.text.isNotEmpty && dateAndTime != null) {
        String formattedDate = DateFormat("dd-MMM-yyyy").format(dateAndTime!);
        query = query.where('whenDates', isEqualTo: formattedDate);
        print("🔍 [FREIGHT] Date filter: $formattedDate");
      }

      // Add zone filter if driver has zones
      if (driverModel.value.zoneIds != null &&
          driverModel.value.zoneIds!.isNotEmpty) {
        query = query.where('zoneId', whereIn: driverModel.value.zoneIds);
        print("🔍 [FREIGHT] Zone filter: ${driverModel.value.zoneIds}");
      }

      print("🔍 [FREIGHT] Executing Firestore query...");
      QuerySnapshot querySnapshot = await query.get();
      print(
          "🔍 [FREIGHT] Found ${querySnapshot.docs.length} freight orders (pre-filter)");

      final uid = FireStoreUtils.getCurrentUid();
      int kept = 0;

      for (var doc in querySnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // ✅ Client-side SOURCE match (lenient - if source is provided)
          bool sourceOk = true;
          if (srcText.isNotEmpty) {
            sourceOk =
                _eqOrContains(data['sourceLocationName'] as String?, srcText) ||
                    _eqOrContains(data['sourceName_norm'] as String?, srcText);
          }

          // ✅ Client-side DESTINATION match (lenient - if destination is provided)
          bool destOk = true;
          if (dstText.isNotEmpty) {
            destOk = _eqOrContains(
                    data['destinationLocationName'] as String?, dstText) ||
                _eqOrContains(data['destinationName_norm'] as String?, dstText);
          }

          if (!(sourceOk && destOk)) {
            print("   ⏭️ Order ${doc.id} skipped: location mismatch");
            continue;
          }

          InterCityOrderModel orderModel = InterCityOrderModel.fromJson(data);

          // Check if already accepted by this driver
          bool alreadyAccepted = false;
          if (orderModel.acceptedDriverId != null &&
              orderModel.acceptedDriverId!.isNotEmpty) {
            if (orderModel.acceptedDriverId is List) {
              alreadyAccepted = (orderModel.acceptedDriverId as List)
                  .cast<String>()
                  .contains(uid);
            } else if (orderModel.acceptedDriverId is String) {
              alreadyAccepted = orderModel.acceptedDriverId == uid;
            }
          }

          if (!alreadyAccepted) {
            freightServiceOrder.add(orderModel);
            kept++;
            print("   ✅ Order ${doc.id} added to freight list");
          } else {
            print("   ⏭️ Order ${doc.id} already accepted by driver");
          }
        } catch (e) {
          print("   ❌ Error parsing order document ${doc.id}: $e");
        }
      }

      print("🔍 [FREIGHT] Final result: $kept freight orders displayed");

      if (kept == 0) {
        print("⚠️ [FREIGHT] No freight orders found. Check:");
        print(
            "   1. Are there freight orders with intercityServiceId = 'Kn2VEnPI3ikF58uK8YqY'?");
        print("   2. Are they in 'ridePlaced' status?");
        print("   3. Do they match the search criteria?");
        print("   4. Are they in the driver's zones?");
      }
    } catch (e) {
      print("❌ [FREIGHT] Error searching freight orders: $e");
    } finally {
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

  getDriver() async {
    updateCurrentLocation();
    FireStoreUtils.fireStore
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

  getActiveRide() {
    FirebaseFirestore.instance
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

  updateCurrentLocation() async {
    PermissionStatus permissionStatus = await location.hasPermission();
    if (permissionStatus == PermissionStatus.granted) {
      location.enableBackgroundMode(enable: true);
      location.changeSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter:
              double.parse(Constant.driverLocationUpdate.toString()),
          interval: 2000);
      location.onLocationChanged.listen((locationData) {
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
    } else {
      location.requestPermission().then((permissionStatus) {
        if (permissionStatus == PermissionStatus.granted) {
          location.enableBackgroundMode(enable: true);
          location.changeSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter:
                  double.parse(Constant.driverLocationUpdate.toString()),
              interval: 2000);
          location.onLocationChanged.listen((locationData) async {
            Constant.currentLocation = LocationLatLng(
                latitude: locationData.latitude,
                longitude: locationData.longitude);

            FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid())
                .then((value) {
              DriverUserModel driverUserModel = value!;
              if (driverUserModel.isOnline == true) {
                driverUserModel.location = LocationLatLng(
                    latitude: locationData.latitude,
                    longitude: locationData.longitude);
                driverUserModel.rotation = locationData.heading;
                GeoFirePoint position = Geoflutterfire().point(
                    latitude: locationData.latitude!,
                    longitude: locationData.longitude!);

                driverUserModel.position = Positions(
                    geoPoint: position.geoPoint, geohash: position.hash);

                FireStoreUtils.updateDriverUser(driverUserModel);
              }
            });
          });
        }
      });
    }
    isLoading.value = false;
    update();
  }

  @override
  void onClose() {
    sourceCityController.value.dispose();
    destinationCityController.value.dispose();
    whenController.value.dispose();
    suggestedTimeController.value.dispose();
    enterOfferRateController.value.dispose();
    super.onClose();
  }
}
