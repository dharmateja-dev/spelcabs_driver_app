import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/order/location_lat_lng.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/intercity_order_model.dart';
import 'package:driver/model/zone_model.dart';
import 'package:driver/utils/app_logger.dart';
import 'package:driver/utils/fire_store_utils.dart';

/// DriverAssignmentValidator
///
/// This service handles zone-based validation for driver assignment.
///
/// Key validation rules based on test cases:
///
/// TC01: Local Driver Assignment
///   - Driver must be ONLINE
///   - Driver must be within the pickup zone (or within radius of pickup location)
///   - Driver receives ride notification
///
/// TC02: Out-of-State Driver Blocking
///   - Driver in a different state/zone should NOT receive notifications
///   - Even if driver is online, location matters
///
/// TC03: Offline Local Driver
///   - Driver with app status set to "Offline" should NOT receive notifications
///   - Even if driver is in the correct zone
///
/// TC04: Twin City Driver Dispatch
///   - Merged zones (twin cities like Durg-Bhilai) should be treated as one zone
///   - Drivers in twin city zones should receive notifications for rides in merged zones
///
class DriverAssignmentValidator {
  static const String tag = "DriverAssignmentValidator";

  // Default radius in kilometers for driver proximity check
  static const double defaultRadiusKm = 5.0;

  // Twin city configurations (merged zones)
  // Each list represents cities that should be treated as a single zone
  static const List<List<String>> twinCityGroups = [
    ['durg', 'bhilai'],
    ['hyderabad', 'secunderabad'],
    ['delhi', 'new delhi', 'noida', 'gurgaon', 'gurugram'],
    ['mumbai', 'navi mumbai', 'thane'],
    ['kolkata', 'howrah'],
  ];

  /// Validates whether a driver should receive a ride notification
  ///
  /// Returns `true` if the driver should receive the notification,
  /// `false` otherwise.
  ///
  /// Validation checks:
  /// 1. Driver must be online (isOnline == true)
  /// 2. Driver must be within the ride's zone OR within proximity radius
  /// 3. Driver's zone must match the ride's zone (considering twin cities)
  static Future<DriverAssignmentResult> shouldDriverReceiveRide({
    required DriverUserModel driver,
    required LocationLatLng ridePickupLocation,
    required String? rideZoneId,
    required List<ZoneModel> availableZones,
    double? customRadiusKm,
  }) async {
    AppLogger.debug(
      "Validating driver ${driver.id} for ride in zone $rideZoneId",
      tag: tag,
    );

    // TC03: Check if driver is online
    if (driver.isOnline != true) {
      AppLogger.debug(
        "Driver ${driver.id} is OFFLINE - NOT eligible for ride",
        tag: tag,
      );
      return DriverAssignmentResult(
        isEligible: false,
        reason: DriverIneligibilityReason.driverOffline,
        message: "Driver is offline",
      );
    }

    // Check if driver has a valid location
    if (driver.location == null ||
        driver.location!.latitude == null ||
        driver.location!.longitude == null) {
      AppLogger.debug(
        "Driver ${driver.id} has no valid location - NOT eligible for ride",
        tag: tag,
      );
      return DriverAssignmentResult(
        isEligible: false,
        reason: DriverIneligibilityReason.noDriverLocation,
        message: "Driver location is unavailable",
      );
    }

    // TC02: Check if driver is in the correct zone (state-level check)
    final bool zoneMatch = await _validateDriverZone(
      driver: driver,
      rideZoneId: rideZoneId,
      ridePickupLocation: ridePickupLocation,
      availableZones: availableZones,
    );

    if (!zoneMatch) {
      AppLogger.debug(
        "Driver ${driver.id} is in a different zone/state - NOT eligible for ride",
        tag: tag,
      );
      return DriverAssignmentResult(
        isEligible: false,
        reason: DriverIneligibilityReason.outsideZone,
        message: "Driver is outside the ride's zone",
      );
    }

    // TC01: Check if driver is within proximity radius of the pickup location
    final double radiusKm =
        customRadiusKm ?? (double.tryParse(Constant.radius) ?? defaultRadiusKm);

    final double distanceKm = _calculateHaversineDistance(
      driver.location!.latitude!,
      driver.location!.longitude!,
      ridePickupLocation.latitude!,
      ridePickupLocation.longitude!,
    );

    if (distanceKm > radiusKm) {
      AppLogger.debug(
        "Driver ${driver.id} is ${distanceKm.toStringAsFixed(2)}km away (max: ${radiusKm}km) - NOT eligible",
        tag: tag,
      );
      return DriverAssignmentResult(
        isEligible: false,
        reason: DriverIneligibilityReason.outsideRadius,
        message:
            "Driver is ${distanceKm.toStringAsFixed(1)}km away from pickup (max: ${radiusKm.toStringAsFixed(1)}km)",
      );
    }

    // All checks passed - driver is eligible
    AppLogger.info(
      "Driver ${driver.id} is ELIGIBLE for ride (distance: ${distanceKm.toStringAsFixed(2)}km)",
      tag: tag,
    );
    return DriverAssignmentResult(
      isEligible: true,
      reason: null,
      message: "Driver is eligible for this ride",
      distanceKm: distanceKm,
    );
  }

  /// Validates whether a driver's zone matches the ride's zone
  /// Considers twin city merging for adjacent cities
  static Future<bool> _validateDriverZone({
    required DriverUserModel driver,
    required String? rideZoneId,
    required LocationLatLng ridePickupLocation,
    required List<ZoneModel> availableZones,
  }) async {
    // If no zone ID is specified for the ride, allow all drivers
    if (rideZoneId == null || rideZoneId.isEmpty) {
      AppLogger.debug("Ride has no zone restriction", tag: tag);
      return true;
    }

    // If driver has no assigned zones, they cannot receive rides
    if (driver.zoneIds == null || driver.zoneIds!.isEmpty) {
      AppLogger.debug(
        "Driver ${driver.id} has no assigned zones",
        tag: tag,
      );
      return false;
    }

    // Get the ride zone details
    ZoneModel? rideZone;
    try {
      rideZone = availableZones.firstWhere(
        (zone) => zone.id == rideZoneId,
      );
    } catch (e) {
      AppLogger.warning(
        "Ride zone $rideZoneId not found in available zones",
        tag: tag,
      );
    }

    // Direct zone match - driver is assigned to the ride's zone
    if (driver.zoneIds!.contains(rideZoneId)) {
      AppLogger.debug(
        "Driver ${driver.id} directly assigned to ride zone $rideZoneId",
        tag: tag,
      );
      return true;
    }

    // TC04: Check for twin city match
    final bool isTwinCityMatch = await _checkTwinCityMatch(
      driverZoneIds:
          List<String>.from(driver.zoneIds!.map((e) => e.toString())),
      rideZoneId: rideZoneId,
      availableZones: availableZones,
    );

    if (isTwinCityMatch) {
      AppLogger.debug(
        "Driver ${driver.id} is in a twin city zone matching $rideZoneId",
        tag: tag,
      );
      return true;
    }

    // Check if driver is physically inside the ride zone polygon
    if (rideZone != null &&
        rideZone.area != null &&
        rideZone.area!.isNotEmpty) {
      final bool isInsideZone = _isPointInPolygon(
        driver.location!.latitude!,
        driver.location!.longitude!,
        rideZone.area!,
      );

      if (isInsideZone) {
        AppLogger.debug(
          "Driver ${driver.id} is physically inside ride zone $rideZoneId",
          tag: tag,
        );
        return true;
      }
    }

    return false;
  }

  /// Checks if driver's zones are twin cities of the ride zone
  ///
  /// TC04: Twin City Driver Dispatch
  /// Example: Driver in Bhilai should receive rides for Durg (and vice versa)
  static Future<bool> _checkTwinCityMatch({
    required List<String> driverZoneIds,
    required String rideZoneId,
    required List<ZoneModel> availableZones,
  }) async {
    // Get zone names for comparison
    String rideZoneName;
    try {
      final ZoneModel rideZone = availableZones.firstWhere(
        (zone) => zone.id == rideZoneId,
      );
      rideZoneName = Constant.localizationName(rideZone.name);
    } catch (e) {
      AppLogger.debug("Could not find ride zone name for $rideZoneId",
          tag: tag);
      return false;
    }

    if (rideZoneName.isEmpty) {
      return false;
    }

    final String normalizedRideZoneName = rideZoneName.toLowerCase().trim();

    // Get driver zone names
    List<String> driverZoneNames = [];
    for (String driverZoneId in driverZoneIds) {
      try {
        final ZoneModel driverZone = availableZones.firstWhere(
          (zone) => zone.id == driverZoneId,
        );
        final String name = Constant.localizationName(driverZone.name);
        if (name.isNotEmpty) {
          driverZoneNames.add(name.toLowerCase().trim());
        }
      } catch (e) {
        // Zone not found, continue
      }
    }

    // Check if ride zone and any driver zone belong to the same twin city group
    for (List<String> twinGroup in twinCityGroups) {
      final bool rideInGroup = twinGroup.any(
        (city) =>
            normalizedRideZoneName.contains(city) ||
            city.contains(normalizedRideZoneName),
      );

      if (rideInGroup) {
        // Check if any driver zone is also in this twin group
        for (String driverZoneName in driverZoneNames) {
          final bool driverInGroup = twinGroup.any(
            (city) =>
                driverZoneName.contains(city) || city.contains(driverZoneName),
          );

          if (driverInGroup) {
            AppLogger.debug(
              "Twin city match found: Driver zone '$driverZoneName' and ride zone '$normalizedRideZoneName' are in the same group",
              tag: tag,
            );
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Checks if a point (lat, lng) is inside a polygon defined by GeoPoints
  /// Uses the Ray Casting algorithm
  static bool _isPointInPolygon(
      double lat, double lng, List<GeoPoint> polygon) {
    if (polygon.isEmpty || polygon.length < 3) return false;

    int intersections = 0;
    final int n = polygon.length;

    for (int i = 0; i < n; i++) {
      final GeoPoint p1 = polygon[i];
      final GeoPoint p2 = polygon[(i + 1) % n];

      final double y1 = p1.latitude;
      final double x1 = p1.longitude;
      final double y2 = p2.latitude;
      final double x2 = p2.longitude;

      // Check if the ray from (lat, lng) going right intersects the edge
      if (((y1 <= lat && lat < y2) || (y2 <= lat && lat < y1)) &&
          (lng < (x2 - x1) * (lat - y1) / (y2 - y1) + x1)) {
        intersections++;
      }
    }

    // Point is inside if odd number of intersections
    return (intersections % 2) == 1;
  }

  /// Calculates the Haversine distance between two coordinates in kilometers
  static double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;

    final double dLat = (lat2 - lat1) * (math.pi / 180);
    final double dLon = (lon2 - lon1) * (math.pi / 180);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) *
            math.cos(lat2 * (math.pi / 180)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Filters a list of orders to only include those the driver is eligible for
  ///
  /// This is used to filter the orders stream before showing to the driver
  static Future<List<OrderModel>> filterOrdersForDriver({
    required DriverUserModel driver,
    required List<OrderModel> orders,
    required List<ZoneModel> availableZones,
    double? customRadiusKm,
  }) async {
    List<OrderModel> eligibleOrders = [];

    for (OrderModel order in orders) {
      if (order.sourceLocationLAtLng == null ||
          order.sourceLocationLAtLng!.latitude == null ||
          order.sourceLocationLAtLng!.longitude == null) {
        continue;
      }

      final result = await shouldDriverReceiveRide(
        driver: driver,
        ridePickupLocation: order.sourceLocationLAtLng!,
        rideZoneId: order.zoneId,
        availableZones: availableZones,
        customRadiusKm: customRadiusKm,
      );

      if (result.isEligible) {
        eligibleOrders.add(order);
      }
    }

    AppLogger.info(
      "Filtered ${orders.length} orders to ${eligibleOrders.length} eligible for driver ${driver.id}",
      tag: tag,
    );

    return eligibleOrders;
  }

  /// Filters intercity orders for driver eligibility
  static Future<List<InterCityOrderModel>> filterIntercityOrdersForDriver({
    required DriverUserModel driver,
    required List<InterCityOrderModel> orders,
    required List<ZoneModel> availableZones,
    double? customRadiusKm,
  }) async {
    List<InterCityOrderModel> eligibleOrders = [];

    for (InterCityOrderModel order in orders) {
      if (order.sourceLocationLAtLng == null ||
          order.sourceLocationLAtLng!.latitude == null ||
          order.sourceLocationLAtLng!.longitude == null) {
        continue;
      }

      final result = await shouldDriverReceiveRide(
        driver: driver,
        ridePickupLocation: order.sourceLocationLAtLng!,
        rideZoneId: order.zoneId,
        availableZones: availableZones,
        customRadiusKm: customRadiusKm,
      );

      if (result.isEligible) {
        eligibleOrders.add(order);
      }
    }

    AppLogger.info(
      "Filtered ${orders.length} intercity orders to ${eligibleOrders.length} eligible for driver ${driver.id}",
      tag: tag,
    );

    return eligibleOrders;
  }

  /// Gets all zones from Firestore (cached for performance)
  static List<ZoneModel>? _cachedZones;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 5);

  static Future<List<ZoneModel>> getAvailableZones(
      {bool forceRefresh = false}) async {
    // Check if cache is valid
    if (!forceRefresh &&
        _cachedZones != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedZones!;
    }

    // Fetch zones from Firestore
    final zones = await FireStoreUtils.getZone();
    _cachedZones = zones ?? [];
    _cacheTimestamp = DateTime.now();

    return _cachedZones!;
  }

  /// Clears the zone cache
  static void clearZoneCache() {
    _cachedZones = null;
    _cacheTimestamp = null;
  }
}

/// Result class for driver assignment validation
class DriverAssignmentResult {
  final bool isEligible;
  final DriverIneligibilityReason? reason;
  final String message;
  final double? distanceKm;

  DriverAssignmentResult({
    required this.isEligible,
    required this.reason,
    required this.message,
    this.distanceKm,
  });

  @override
  String toString() {
    return 'DriverAssignmentResult(isEligible: $isEligible, reason: $reason, message: $message, distanceKm: ${distanceKm?.toStringAsFixed(2)})';
  }
}

/// Enum for driver ineligibility reasons
enum DriverIneligibilityReason {
  driverOffline, // TC03: Driver's app status is "Offline"
  noDriverLocation, // Driver's location is unavailable
  outsideZone, // TC02: Driver is in a different zone/state
  outsideRadius, // TC01: Driver is too far from pickup location
}
