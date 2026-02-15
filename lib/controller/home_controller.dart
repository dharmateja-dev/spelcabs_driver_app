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
import 'package:geolocator/geolocator.dart' as geo;
import 'package:driver/utils/app_logger.dart';
import 'package:driver/utils/location_permission_helper.dart';
import 'package:driver/services/city_rides_listener_service.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
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
  StreamSubscription<geo.ServiceStatus>? _serviceStatusSubscription;

  /// Flag to track if we're waiting for location to be enabled
  bool _waitingForLocationService = false;

  /// Time of the last successful Firestore location update (for throttling)
  DateTime? _lastFirestoreWriteTime;

  /// Current tracking mode (to avoid redundant setting updates)
  bool _isHighFrequencyMode = false;

  void onItemTapped(int index) {
    selectedIndex.value = index;
    AppLogger.info("Bottom navigation item tapped: $index",
        tag: "HomeController");
  }

  @override
  void onInit() {
    AppLogger.debug("HomeController onInit called.", tag: "HomeController");
    WidgetsBinding.instance.addObserver(this);
    _startLocationServiceMonitoring();
    getDriver();
    getActiveRide();
    updateCurrentLocation(); // Ensure this is called to start location updates
    super.onInit();
  }

  /// Monitor location service status changes (when user enables/disables GPS)
  void _startLocationServiceMonitoring() {
    _serviceStatusSubscription = geo.Geolocator.getServiceStatusStream().listen(
      (geo.ServiceStatus status) {
        AppLogger.info("Location service status changed: $status",
            tag: "HomeController");
        if (status == geo.ServiceStatus.enabled && _waitingForLocationService) {
          _waitingForLocationService = false;
          AppLogger.info(
              "Location service enabled, re-initializing location...",
              tag: "HomeController");
          updateCurrentLocation();
        }
      },
      onError: (error) {
        AppLogger.error("Error monitoring location service status: $error",
            tag: "HomeController", error: error);
      },
    );
  }

  /// Handle app lifecycle changes - re-check location when app resumes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    AppLogger.debug("App lifecycle state changed: $state",
        tag: "HomeController");

    if (state == AppLifecycleState.resumed) {
      // App came back to foreground - check if location is now available
      _checkAndReinitializeLocation();
    }
  }

  /// Check if location is now available and reinitialize if needed
  Future<void> _checkAndReinitializeLocation() async {
    try {
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      AppLogger.debug(
          "Location service enabled check on resume: $serviceEnabled",
          tag: "HomeController");

      if (serviceEnabled && !isLocationInitialized.value) {
        AppLogger.info(
            "Location service now available, initializing location...",
            tag: "HomeController");
        await updateCurrentLocation();
      } else if (serviceEnabled && isLocationInitialized.value) {
        // Already initialized but came back from settings - refresh location
        AppLogger.debug("Location already initialized, refreshing...",
            tag: "HomeController");
        // Get a fresh location update
        try {
          final locationData = await location.getLocation();
          if (locationData.latitude != null && locationData.longitude != null) {
            _updateSearchLocationIfNeeded(
                locationData.latitude!, locationData.longitude!);
          }
        } catch (e) {
          AppLogger.warning("Could not refresh location on resume: $e",
              tag: "HomeController");
        }
      } else if (!serviceEnabled) {
        _waitingForLocationService = true;
        AppLogger.debug(
            "Location service still disabled, waiting for user to enable...",
            tag: "HomeController");
      }
    } catch (e) {
      AppLogger.error("Error checking location on app resume: $e",
          tag: "HomeController", error: e);
    }
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

        // Update city rides listener with driver status
        CityRidesListenerService().updateDriverStatus(driverModel.value);
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

          // Adaptive Location Tracking:
          // If there are active rides, switch to high frequency mode.
          // Otherwise, use idle mode (battery saving).
          _updateLocationSettings(isActive: isActiveValue.value > 0);
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
      _waitingForLocationService = true;
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
    try {
      await location.enableBackgroundMode(enable: true);
      AppLogger.info("Location background mode enabled.",
          tag: "HomeController");
    } catch (e) {
      AppLogger.warning("Failed to enable background mode: $e",
          tag: "HomeController");
    }

    try {
      // Start with idle settings by default, active listener will upgrade if needed
      _updateLocationSettings(
          isActive: isActiveValue.value > 0, forceUpdate: true);

      AppLogger.info("Location settings initialized.", tag: "HomeController");
    } catch (e) {
      AppLogger.warning("Failed to change location settings: $e",
          tag: "HomeController");
    }

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

          // Start city rides listener when location is first initialized
          if (driverModel.value.id != null &&
              driverModel.value.isOnline == true) {
            CityRidesListenerService().startListening(
              driver: driverModel.value,
              location: LocationLatLng(
                latitude: locationData.latitude,
                longitude: locationData.longitude,
              ),
            );
          }
        } else {
          // Update listener location when driver moves significantly
          CityRidesListenerService().updateLocation(
            LocationLatLng(
              latitude: locationData.latitude,
              longitude: locationData.longitude,
            ),
          );
          // Update listener location when driver moves significantly
          CityRidesListenerService().updateLocation(
            LocationLatLng(
              latitude: locationData.latitude,
              longitude: locationData.longitude,
            ),
          );
        }

        // Throttle Firestore updates
        _updateDriverLocationInFirestore(locationData);
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

  /// Updates location tracking settings based on whether there is an active ride.
  Future<void> _updateLocationSettings(
      {required bool isActive, bool forceUpdate = false}) async {
    if (_isHighFrequencyMode == isActive && !forceUpdate) {
      return; // No change needed
    }

    _isHighFrequencyMode = isActive;

    try {
      if (isActive) {
        AppLogger.info("Switching to ACTIVE location tracking (High Frequency)",
            tag: "HomeController");
        await location.changeSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: Constant.locationActiveDistanceFilter,
          interval: Constant.locationActiveInterval,
        );
      } else {
        AppLogger.info("Switching to IDLE location tracking (Power Saving)",
            tag: "HomeController");
        await location.changeSettings(
          accuracy:
              LocationAccuracy.high, // Keep high for accurate pickup detection
          distanceFilter: Constant.locationIdleDistanceFilter,
          interval: Constant.locationIdleInterval,
        );
      }
    } catch (e) {
      AppLogger.error("Failed to update location settings: $e",
          tag: "HomeController", error: e);
    }
  }

  /// Updates driver location in Firestore with throttling to save costs/data.
  void _updateDriverLocationInFirestore(LocationData locationData) {
    // Check throttling
    final now = DateTime.now();
    if (_lastFirestoreWriteTime != null) {
      final difference =
          now.difference(_lastFirestoreWriteTime!).inMilliseconds;
      if (difference < Constant.firestoreWriteThrottleMs) {
        // AppLogger.debug("Skipping Firestore update (Throttled)", tag: "HomeController");
        return;
      }
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

          driverUserModel.position =
              Positions(geoPoint: position.geoPoint, geohash: position.hash);
          driverUserModel.rotation = locationData.heading;

          FireStoreUtils.updateDriverUser(driverUserModel);

          // Update the last write time
          _lastFirestoreWriteTime = DateTime.now();

          AppLogger.debug(
              "Driver location and rotation updated in Firestore (Throttled).",
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
  }

  @override
  void onClose() {
    AppLogger.debug("HomeController onClose called, cancelling subscriptions.",
        tag: "HomeController");
    WidgetsBinding.instance.removeObserver(this);
    _driverSubscription?.cancel();
    _activeRideSubscription?.cancel();
    _locationSubscription?.cancel();
    _serviceStatusSubscription?.cancel();

    // Stop city rides listener (but don't clear - driver may still be logged in)
    CityRidesListenerService().stopListening();

    super.onClose();
  }
}
