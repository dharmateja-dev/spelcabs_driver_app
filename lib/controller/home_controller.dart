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

  void onItemTapped(int index) {
    selectedIndex.value = index;
    AppLogger.info("Bottom navigation item tapped: $index", tag: "HomeController");
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

  getDriver() async {
    AppLogger.debug("getDriver called.", tag: "HomeController");
    FireStoreUtils.fireStore
        .collection(CollectionName.driverUsers)
        .doc(FireStoreUtils.getCurrentUid())
        .snapshots()
        .listen((event) {
      if (event.exists) {
        driverModel.value = DriverUserModel.fromJson(event.data()!);
        AppLogger.info("Driver data updated: ${driverModel.value.fullName}", tag: "HomeController");
      } else {
        AppLogger.warning("Driver document does not exist for current UID: ${FireStoreUtils.getCurrentUid()}", tag: "HomeController");
      }
    }, onError: (error) {
      AppLogger.error("Error fetching driver data: $error", tag: "HomeController", error: error);
    });
    // updateCurrentLocation(); // Removed from here as it's now in onInit() to ensure it starts early
  }

  RxInt isActiveValue = 0.obs;

  getActiveRide() {
    AppLogger.debug("getActiveRide called.", tag: "HomeController");
    FirebaseFirestore.instance
        .collection(CollectionName.orders)
        .where('driverId', isEqualTo: FireStoreUtils.getCurrentUid())
        .where('status',
        whereIn: [Constant.rideInProgress, Constant.rideActive])
        .snapshots()
        .listen((event) {
      isActiveValue.value = event.size;
      AppLogger.info("Active rides count updated: ${isActiveValue.value}", tag: "HomeController");
    }, onError: (error) {
      AppLogger.error("Error fetching active rides: $error", tag: "HomeController", error: error);
    });
  }

  Location location = Location();

  updateCurrentLocation() async {
    AppLogger.debug("updateCurrentLocation called.", tag: "HomeController");
    PermissionStatus permissionStatus = await location.hasPermission();
    AppLogger.info("Location permission status: $permissionStatus", tag: "HomeController");

    if (permissionStatus == PermissionStatus.granted) {
      location.enableBackgroundMode(enable: true);
      location.changeSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter:
          double.parse(Constant.driverLocationUpdate.toString()),
          interval: 2000);
      AppLogger.info("Location background mode enabled and settings changed.", tag: "HomeController");

      location.onLocationChanged.listen((locationData) {
        if (locationData.latitude != null && locationData.longitude != null) { //EDIT: Ensure valid location data
          Constant.currentLocation = LocationLatLng(
              latitude: locationData.latitude, longitude: locationData.longitude);
          AppLogger.debug("Location updated: ${locationData.latitude}, ${locationData.longitude}", tag: "HomeController");

          //EDIT: Set location initialized flag to true after first valid location
          if (!isLocationInitialized.value) { //EDIT
            isLocationInitialized.value = true; //EDIT
            AppLogger.info("Location initialized for the first time.", tag: "HomeController"); //EDIT
          } //EDIT

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

                driverUserModel.position =
                    Positions(geoPoint: position.geoPoint, geohash: position.hash);
                driverUserModel.rotation = locationData.heading;
                FireStoreUtils.updateDriverUser(driverUserModel);
                AppLogger.debug("Driver location and rotation updated in Firestore.", tag: "HomeController");
              } else {
                AppLogger.info("Driver is offline, not updating location in Firestore.", tag: "HomeController");
              }
            } else {
              AppLogger.warning("Driver profile not found when trying to update location.", tag: "HomeController");
            }
          }).catchError((error) {
            AppLogger.error("Error getting driver profile for location update: $error", tag: "HomeController", error: error);
          });
        } else { //EDIT
          AppLogger.warning("Received null latitude or longitude from location update.", tag: "HomeController"); //EDIT
        } //EDIT
      });
    } else {
      AppLogger.warning("Location permission not granted, requesting permission.", tag: "HomeController");
      location.requestPermission().then((permissionStatus) {
        AppLogger.info("Location permission requested, new status: $permissionStatus", tag: "HomeController");
        if (permissionStatus == PermissionStatus.granted) {
          location.enableBackgroundMode(enable: true);
          location.changeSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter:
              double.parse(Constant.driverLocationUpdate.toString()),
              interval: 2000);
          AppLogger.info("Location background mode enabled and settings changed after permission request.", tag: "HomeController");

          location.onLocationChanged.listen((locationData) async {
            if (locationData.latitude != null && locationData.longitude != null) { //EDIT: Ensure valid location data
              Constant.currentLocation = LocationLatLng(
                  latitude: locationData.latitude,
                  longitude: locationData.longitude);
              AppLogger.debug("Location updated (after permission request): ${locationData.latitude}, ${locationData.longitude}", tag: "HomeController");

              //EDIT: Set location initialized flag to true after first valid location (after permission request)
              if (!isLocationInitialized.value) { //EDIT
                isLocationInitialized.value = true; //EDIT
                AppLogger.info("Location initialized for the first time (after permission request).", tag: "HomeController"); //EDIT
              } //EDIT

              FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid())
                  .then((value) {
                if (value != null) {
                  DriverUserModel driverUserModel = value;
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
                    AppLogger.debug("Driver location and rotation updated in Firestore (after permission request).", tag: "HomeController");
                  } else {
                    AppLogger.info("Driver is offline, not updating location in Firestore (after permission request).", tag: "HomeController");
                  }
                } else {
                  AppLogger.warning("Driver profile not found when trying to update location (after permission request).", tag: "HomeController");
                }
              }).catchError((error) {
                AppLogger.error("Error getting driver profile for location update (after permission request): $error", tag: "HomeController", error: error);
              });
            } else { //EDIT
              AppLogger.warning("Received null latitude or longitude from location update (after permission request).", tag: "HomeController"); //EDIT
            } //EDIT
          });
        }
      });
    }
    isLoading.value = false;
    update();
    AppLogger.debug("HomeController isLoading set to false.", tag: "HomeController");
  }
}
