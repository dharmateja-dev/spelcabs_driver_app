import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/controller/dash_board_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/order/location_lat_lng.dart';
import 'package:driver/model/order/positions.dart';
import 'package:driver/ui/home_screens/accepted_orders.dart';
import 'package:driver/ui/home_screens/active_order_screen.dart';
import 'package:driver/ui/home_screens/new_orders_screen.dart';
import 'package:driver/ui/order_screen/order_screen.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:driver/widget/geoflutterfire/src/models/point.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:driver/utils/app_logger.dart';
import 'package:driver/utils/location_permission_helper.dart';

class HomeController extends GetxController {
  RxInt selectedIndex = 0.obs;
  List<Widget> widgetOptions = <Widget>[
    const NewOrderScreen(),
    const AcceptedOrders(),
    const ActiveOrderScreen(),
    const OrderScreen(),
  ];
  DashBoardController dashboardController = Get.put(DashBoardController());

  // New observable to track if location has been initialized
  RxBool isLocationInitialized = false.obs;

  /// Observable location used for searching nearby orders.
  /// This only updates when the driver moves more than 500 meters,
  /// preventing excessive stream rebuilds while still keeping the ride list current.
  Rx<LocationLatLng?> searchLocation = Rx<LocationLatLng?>(null);

  /// Minimum distance (in meters) the driver must move before we update the search location.
  static const double _searchLocationThresholdMeters = 500.0;

  /// Stream subscriptions to be cancelled in onClose
  StreamSubscription? _driverSubscription;
  StreamSubscription? _activeRideSubscription;
  StreamSubscription? _locationSubscription;

  void onItemTapped(int index) {
    selectedIndex.value = index;
    AppLogger.info("Bottom navigation item tapped: $index",
        tag: "HomeController");
  }

  @override
  void onInit() {
    AppLogger.debug("HomeController onInit called.", tag: "HomeController");
    getDriver();
    getActiveRide();
    updateCurrentLocation(); // Ensure this is called to start location updates
    super.onInit();
  }

  Rx<DriverUserModel> driverModel = DriverUserModel().obs;
  RxBool isLoading = true.obs;

  Future<void> getDriver() async {
    AppLogger.debug("getDriver called.", tag: "HomeController");
    _driverSubscription = FireStoreUtils.fireStore
        .collection(CollectionName.driverUsers)
        .doc(FireStoreUtils.getCurrentUid())
        .snapshots()
        .listen((event) {
      if (event.exists) {
        driverModel.value = DriverUserModel.fromJson(event.data()!);
        AppLogger.info("Driver data updated: ${driverModel.value.fullName}",
            tag: "HomeController");
      } else {
        AppLogger.warning(
            "Driver document does not exist for current UID: ${FireStoreUtils.getCurrentUid()}",
            tag: "HomeController");
      }
    }, onError: (error) {
      AppLogger.error("Error fetching driver data: $error",
          tag: "HomeController", error: error);
    });
    // updateCurrentLocation(); // Removed from here as it's now in onInit() to ensure it starts early
  }

  RxInt isActiveValue = 0.obs;

  void getActiveRide() {
    AppLogger.debug("getActiveRide called.", tag: "HomeController");
    _activeRideSubscription = FirebaseFirestore.instance
        .collection(CollectionName.orders)
        .where('driverId', isEqualTo: FireStoreUtils.getCurrentUid())
        .where('status',
            whereIn: [Constant.rideInProgress, Constant.rideActive])
        .snapshots()
        .listen((event) {
          isActiveValue.value = event.size;
          AppLogger.info("Active rides count updated: ${isActiveValue.value}",
              tag: "HomeController");
        }, onError: (error) {
          AppLogger.error("Error fetching active rides: $error",
              tag: "HomeController", error: error);
        });
  }

  Location location = Location();

  Future<void> updateCurrentLocation() async {
    AppLogger.debug("updateCurrentLocation called.", tag: "HomeController");

    // Use the new LocationPermissionHelper
    final hasPermission =
        await LocationPermissionHelper.checkAndRequestLocationPermission(
      showEducationalDialog: true,
    );

    if (!hasPermission) {
      AppLogger.warning("Location permission not granted.",
          tag: "HomeController");
      isLoading.value = false;
      update();
      return;
    }

    // Request background location permission for drivers
    final hasBackgroundPermission =
        await LocationPermissionHelper.requestBackgroundLocationPermission();
    if (!hasBackgroundPermission) {
      AppLogger.warning(
          "Background location permission not granted. App will work with limited functionality.",
          tag: "HomeController");
      // Continue anyway - app can work with "While Using" permission
    }

    // Permission granted, set up location tracking
    location.enableBackgroundMode(enable: true);
    location.changeSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: double.parse(Constant.driverLocationUpdate.toString()),
        interval: 2000);
    AppLogger.info("Location background mode enabled and settings changed.",
        tag: "HomeController");

    _locationSubscription = location.onLocationChanged.listen((locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        Constant.currentLocation = LocationLatLng(
            latitude: locationData.latitude, longitude: locationData.longitude);
        AppLogger.debug(
            "Location updated: ${locationData.latitude}, ${locationData.longitude}",
            tag: "HomeController");

        // Update search location if driver has moved significantly
        _updateSearchLocationIfNeeded(
            locationData.latitude!, locationData.longitude!);

        if (!isLocationInitialized.value) {
          isLocationInitialized.value = true;
          AppLogger.info("Location initialized for the first time.",
              tag: "HomeController");
        }

        FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid())
            .then((value) {
          if (value != null) {
            DriverUserModel driverUserModel = value;
            if (driverUserModel.isOnline == true) {
              driverUserModel.location = LocationLatLng(
                  latitude: locationData.latitude,
                  longitude: locationData.longitude);
              GeoFirePoint position = Geoflutterfire().point(
                  latitude: locationData.latitude!,
                  longitude: locationData.longitude!);

              driverUserModel.position = Positions(
                  geoPoint: position.geoPoint, geohash: position.hash);
              driverUserModel.rotation = locationData.heading;
              FireStoreUtils.updateDriverUser(driverUserModel);
              AppLogger.debug(
                  "Driver location and rotation updated in Firestore.",
                  tag: "HomeController");
            } else {
              AppLogger.info(
                  "Driver is offline, not updating location in Firestore.",
                  tag: "HomeController");
            }
          } else {
            AppLogger.warning(
                "Driver profile not found when trying to update location.",
                tag: "HomeController");
          }
        }).catchError((error) {
          AppLogger.error(
              "Error getting driver profile for location update: $error",
              tag: "HomeController",
              error: error);
        });
      } else {
        AppLogger.warning(
            "Received null latitude or longitude from location update.",
            tag: "HomeController");
      }
    });

    isLoading.value = false;
    update();
    AppLogger.debug("HomeController isLoading set to false.",
        tag: "HomeController");
  }

  /// Updates the searchLocation only if the driver has moved more than the threshold distance.
  /// This prevents excessive stream rebuilds while keeping the ride list current.
  void _updateSearchLocationIfNeeded(double newLat, double newLng) {
    final current = searchLocation.value;

    if (current == null) {
      // First location update - always set it
      searchLocation.value =
          LocationLatLng(latitude: newLat, longitude: newLng);
      AppLogger.info("Search location initialized: ($newLat, $newLng)",
          tag: "HomeController");
      return;
    }

    // Calculate distance from current search location
    final distanceMeters = _calculateHaversineDistanceMeters(
        current.latitude!, current.longitude!, newLat, newLng);

    if (distanceMeters >= _searchLocationThresholdMeters) {
      searchLocation.value =
          LocationLatLng(latitude: newLat, longitude: newLng);
      AppLogger.info(
          "Search location updated (moved ${distanceMeters.toStringAsFixed(0)}m): ($newLat, $newLng)",
          tag: "HomeController");
    }
  }

  /// Calculates the Haversine distance between two coordinates in meters.
  double _calculateHaversineDistanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusMeters = 6371000.0;

    final double dLat = (lat2 - lat1) * (math.pi / 180);
    final double dLon = (lon2 - lon1) * (math.pi / 180);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) *
            math.cos(lat2 * (math.pi / 180)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  @override
  void onClose() {
    AppLogger.debug("HomeController onClose called, cancelling subscriptions.",
        tag: "HomeController");
    _driverSubscription?.cancel();
    _activeRideSubscription?.cancel();
    _locationSubscription?.cancel();
    super.onClose();
  }
}
