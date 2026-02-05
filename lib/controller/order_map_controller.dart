import 'dart:async';
import 'dart:math';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart' as prefix;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:driver/utils/app_logger.dart'; //EDIT

class OrderMapController extends GetxController {
  final Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();
  Rx<TextEditingController> enterOfferRateController =
      TextEditingController().obs;

  RxBool isLoading = true.obs;

  // variables for fare breakdown
  RxDouble baseFare = 0.0.obs;
  RxDouble minuteCharges = 0.0.obs;
  RxDouble totalTaxes = 0.0.obs;
  RxDouble totalExcludingTax =
      0.0.obs; // New variable for subtotal before taxes
  RxDouble totalIncludingTax = 0.0.obs;

  StreamSubscription? _orderSubscription;
  StreamSubscription? _driverSubscription;

  late MapController mapOsmController;
  Rx<RoadInfo> roadInfo = RoadInfo().obs; // Reactive road info for OSM
  Map<String, GeoPoint> osmMarkers = <String, GeoPoint>{}; // OSM markers
  Image? departureOsmIcon; // Custom icon for OSM departure marker
  Image? destinationOsmIcon;

  final double _estimatedTimeInMinutes = 0.0;

  @override
  void onInit() {
    AppLogger.debug("OrderMapController onInit called.",
        tag: "OrderMapController");
    if (Constant.selectedMapType == 'osm') {
      ShowToastDialog.showLoader("Please wait");
      mapOsmController = MapController(
          initPosition: GeoPoint(latitude: 20.9153, longitude: -100.7439),
          useExternalTracking: false); //OSM
      AppLogger.info("OSM map controller initialized.",
          tag: "OrderMapController");
    }
    addMarkerSetup();
    getArgument();

    String? orderId = Get.arguments?['orderModel'];
    AppLogger.info("Order ID from arguments: $orderId",
        tag: "OrderMapController");

    // if (orderId != null) {
    //   _orderSubscription = FireStoreUtils.getOrderByOrderId(orderId).listen((order) async {
    //     if (order != null) {
    //       orderModel.value = order; // Update the reactive orderModel
    //
    //       // Set initial offer rate if available in the order
    //       if (order.offerRate != null && order.offerRate!.isNotEmpty) {
    //         enterOfferRateController.value.text = order.offerRate.toString();
    //       } else {
    //         enterOfferRateController.value.text = "0.0"; // Default if no offer rate
    //       }
    //
    //       await _fetchDurationAndCalculateFare();
    //
    //       if (Constant.selectedMapType == 'google') {
    //         getPolyline();
    //       } else if (Constant.selectedMapType == 'osm') {
    //         getOSMPolyline(Get.context != null ? Theme.of(Get.context!).brightness == Brightness.dark : false);
    //       }
    //
    //       isLoading.value = false;
    //     } else {
    //       print("OrderMapController: Order with ID $orderId not found or deleted.");
    //       ShowToastDialog.showToast("Order not found or has been cancelled.".tr);
    //       isLoading.value = false;
    //       Get.back();
    //     }
    //   }, onError: (error) {
    //     print("OrderMapController: Error fetching order: $error");
    //     ShowToastDialog.showToast("Error loading order data.".tr);
    //     isLoading.value = false;
    //     Get.back();
    //   });
    //
    //   _driverSubscription = FireStoreUtils.fireStore
    //       .collection(CollectionName.driverUsers)
    //       .doc(FireStoreUtils.getCurrentUid())
    //       .snapshots()
    //       .listen((event) {
    //     if (event.exists && event.data() != null) {
    //       driverModel.value = DriverUserModel.fromJson(event.data()!);
    //     }
    //   }, onError: (error) {
    //     print("OrderMapController: Error fetching driver data: $error");
    //   });
    //
    // } else {
    //   print("OrderMapController: No order ID provided to OrderMapScreen.");
    //   ShowToastDialog.showToast("Invalid order request.".tr);
    //   isLoading.value = false;
    //   Get.back();
    // }

    // // Debounce listener for the driver's offer rate text field.
    // // This prevents excessive recalculations while the driver is actively typing.
    // debounce(enterOfferRateController.value, (_) {
    //   // Only recalculate if order data has been loaded and is valid
    //   if (orderModel.value.id != null) {
    //     // When only the bid amount changes, we can reuse the previously calculated
    //     // estimated travel time (_estimatedTimeInMinutes).
    //     calculateFareDetails(estimatedTimeInMinutes: _estimatedTimeInMinutes);
    //   }
    // }, time: const Duration(milliseconds: 500)); // Wait 500ms after last keystroke

    super.onInit();
  }

  @override
  void onClose() {
    AppLogger.debug("OrderMapController onClose called.",
        tag: "OrderMapController");
    // Cancel all Firestore stream subscriptions when the controller is closed
    _orderSubscription?.cancel();
    _driverSubscription?.cancel();
    ShowToastDialog.closeLoader(); // Ensure any active loader is closed
    super.onClose();
  }

  Rx<OrderModel> orderModel = OrderModel().obs;
  Rx<DriverUserModel> driverModel = DriverUserModel().obs;

  RxString newAmount = "0.0".obs;

  Future<void> getArgument() async {
    AppLogger.debug("getArgument called.", tag: "OrderMapController");
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      String orderId = argumentData['orderModel'];
      AppLogger.info("Order ID from arguments: $orderId",
          tag: "OrderMapController");
      await getData(orderId);
      newAmount.value = orderModel.value.offerRate.toString();
      // newAmount.value = orderModel.value.finalRate.toString();
      enterOfferRateController.value.text =
          orderModel.value.offerRate.toString();
      AppLogger.info(
          "Order data loaded. Offer rate: ${orderModel.value.offerRate}",
          tag: "OrderMapController");
      if (Constant.selectedMapType == 'google') {
        getPolyline();
        AppLogger.debug("Getting polyline for Google Maps.",
            tag: "OrderMapController");
      }
    } else {
      AppLogger.warning("No arguments received for OrderMapController.",
          tag: "OrderMapController");
    }

    _driverSubscription = FireStoreUtils.fireStore
        .collection(CollectionName.driverUsers)
        .doc(FireStoreUtils.getCurrentUid())
        .snapshots()
        .listen((event) {
      if (event.exists) {
        driverModel.value = DriverUserModel.fromJson(event.data()!);
        AppLogger.info(
            "Driver model updated from stream: ${driverModel.value.fullName}",
            tag: "OrderMapController");
      } else {
        AppLogger.warning(
            "Driver document does not exist for current UID: ${FireStoreUtils.getCurrentUid()}",
            tag: "OrderMapController");
      }
    }, onError: (error) {
      AppLogger.error("Error fetching driver data in stream: $error",
          tag: "OrderMapController", error: error);
    });
    isLoading.value = false;
    update();
    AppLogger.debug("OrderMapController isLoading set to false.",
        tag: "OrderMapController");
  }

  Future<void> getData(String id) async {
    AppLogger.debug("getData called for order ID: $id",
        tag: "OrderMapController");
    await FireStoreUtils.getOrder(id).then((value) {
      if (value != null) {
        orderModel.value = value;
        AppLogger.info("Order data retrieved for ID: $id",
            tag: "OrderMapController");
      } else {
        AppLogger.warning("Order data not found for ID: $id",
            tag: "OrderMapController");
      }
    }).catchError((error) {
      AppLogger.error("Error retrieving order data for ID $id: $error",
          tag: "OrderMapController", error: error);
    });
  }

  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;

  Future<void> addMarkerSetup() async {
    AppLogger.debug("addMarkerSetup called.", tag: "OrderMapController");
    try {
      if (Constant.selectedMapType == 'google') {
        final Uint8List departure =
            await Constant().getBytesFromAsset('assets/images/pickup.png', 100);
        final Uint8List destination = await Constant()
            .getBytesFromAsset('assets/images/dropoff.png', 100);
        departureIcon = BitmapDescriptor.fromBytes(departure);
        destinationIcon = BitmapDescriptor.fromBytes(destination);
        AppLogger.info("Google Maps marker icons loaded.",
            tag: "OrderMapController");
      } else {
        departureOsmIcon = Image.asset("assets/images/pickup.png",
            width: 30, height: 30); //OSM
        destinationOsmIcon = Image.asset("assets/images/dropoff.png",
            width: 30, height: 30); //OSM
        AppLogger.info("OSM marker icons loaded.", tag: "OrderMapController");
      }
    } catch (e, s) {
      AppLogger.error("Error setting up marker icons: $e",
          tag: "OrderMapController", error: e, stackTrace: s);
    }
  }

  RxMap<MarkerId, Marker> markers = <MarkerId, Marker>{}.obs;
  RxMap<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{}.obs;
  PolylinePoints polylinePoints = PolylinePoints();

  void getPolyline() async {
    AppLogger.debug("getPolyline called.", tag: "OrderMapController");
    if (orderModel.value.sourceLocationLAtLng != null &&
        orderModel.value.destinationLocationLAtLng != null) {
      movePosition();
      List<LatLng> polylineCoordinates = [];
      PolylineRequest polylineRequest = PolylineRequest(
        origin: PointLatLng(
            orderModel.value.sourceLocationLAtLng!.latitude ?? 0.0,
            orderModel.value.sourceLocationLAtLng!.longitude ?? 0.0),
        destination: PointLatLng(
            orderModel.value.destinationLocationLAtLng!.latitude ?? 0.0,
            orderModel.value.destinationLocationLAtLng!.longitude ?? 0.0),
        mode: TravelMode.driving,
      );
      try {
        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: Constant.mapAPIKey,
          request: polylineRequest,
        );
        if (result.points.isNotEmpty) {
          for (var point in result.points) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
          AppLogger.info(
              "Polyline points generated: ${polylineCoordinates.length}",
              tag: "OrderMapController");
        } else {
          AppLogger.warning("No polyline points found: ${result.errorMessage}",
              tag: "OrderMapController");
        }
      } catch (e, s) {
        AppLogger.error("Error getting route between coordinates: $e",
            tag: "OrderMapController", error: e, stackTrace: s);
      }
      _addPolyLine(polylineCoordinates);
      addMarker(
          LatLng(orderModel.value.sourceLocationLAtLng!.latitude ?? 0.0,
              orderModel.value.sourceLocationLAtLng!.longitude ?? 0.0),
          "Source",
          departureIcon);
      addMarker(
          LatLng(orderModel.value.destinationLocationLAtLng!.latitude ?? 0.0,
              orderModel.value.destinationLocationLAtLng!.longitude ?? 0.0),
          "Destination",
          destinationIcon);
      AppLogger.debug("Markers added for Google Maps.",
          tag: "OrderMapController");
    } else {
      AppLogger.warning(
          "Source or destination coordinates are null, cannot get polyline.",
          tag: "OrderMapController");
    }
  }

  double zoomLevel = 0;

  Future<void> movePosition() async {
    AppLogger.debug("movePosition called.", tag: "OrderMapController");
    double distance = double.parse((prefix.Geolocator.distanceBetween(
              orderModel.value.sourceLocationLAtLng!.latitude ?? 0.0,
              orderModel.value.sourceLocationLAtLng!.longitude ?? 0.0,
              orderModel.value.destinationLocationLAtLng!.latitude ?? 0.0,
              orderModel.value.destinationLocationLAtLng!.longitude ?? 0.0,
            ) /
            1609.32)
        .toString());
    LatLng center = LatLng(
      (orderModel.value.sourceLocationLAtLng!.latitude! +
              orderModel.value.destinationLocationLAtLng!.latitude!) /
          2,
      (orderModel.value.sourceLocationLAtLng!.longitude! +
              orderModel.value.destinationLocationLAtLng!.longitude!) /
          2,
    );
    AppLogger.debug("Calculated distance: $distance miles, center: $center",
        tag: "OrderMapController");

    double radiusElevated = (distance / 2) + ((distance / 2) / 2);
    double scale = radiusElevated / 500;

    zoomLevel = 5 - log(scale) / log(2);
    AppLogger.debug("Calculated zoom level: $zoomLevel",
        tag: "OrderMapController");

    final GoogleMapController controller = await mapController.future;
    controller.moveCamera(CameraUpdate.newLatLngZoom(center, zoomLevel));
    AppLogger.info(
        "Google Map camera moved to center with zoom level: $zoomLevel",
        tag: "OrderMapController");
  }

  void _addPolyLine(List<LatLng> polylineCoordinates) {
    AppLogger.debug(
        "_addPolyLine called with ${polylineCoordinates.length} points.",
        tag: "OrderMapController");
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      points: polylineCoordinates,
      width: 6,
    );
    polyLines[id] = polyline;
    AppLogger.info("Polyline added to map.", tag: "OrderMapController");
  }

  void addMarker(LatLng? position, String id, BitmapDescriptor? descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker =
        Marker(markerId: markerId, icon: descriptor!, position: position!);
    markers[markerId] = marker;
    AppLogger.debug("Marker added: $id at ($position)",
        tag: "OrderMapController");
  }

  void getOSMPolyline(themeChange) async {
    AppLogger.debug("getOSMPolyline called with themeChange: $themeChange",
        tag: "OrderMapController");
    try {
      if (orderModel.value.sourceLocationLAtLng != null &&
          orderModel.value.destinationLocationLAtLng != null) {
        setOsmMarker(
          departure: GeoPoint(
              latitude: orderModel.value.sourceLocationLAtLng?.latitude ?? 0.0,
              longitude:
                  orderModel.value.sourceLocationLAtLng?.longitude ?? 0.0),
          destination: GeoPoint(
              latitude:
                  orderModel.value.destinationLocationLAtLng?.latitude ?? 0.0,
              longitude:
                  orderModel.value.destinationLocationLAtLng?.longitude ?? 0.0),
        );
        await mapOsmController.removeLastRoad();
        roadInfo.value = await mapOsmController.drawRoad(
          GeoPoint(
              latitude: orderModel.value.sourceLocationLAtLng?.latitude ?? 0,
              longitude: orderModel.value.sourceLocationLAtLng?.longitude ?? 0),
          GeoPoint(
              latitude:
                  orderModel.value.destinationLocationLAtLng?.latitude ?? 0,
              longitude:
                  orderModel.value.destinationLocationLAtLng?.longitude ?? 0),
          roadType: RoadType.car,
          roadOption: RoadOption(
            roadWidth: 15,
            roadColor:
                themeChange ? AppColors.darkModePrimary : AppColors.primary,
            zoomInto: false,
          ),
        );
        AppLogger.info("OSM road drawn. RoadInfo: ${roadInfo.value.distance}m",
            tag: "OrderMapController");

        updateCameraLocation(
            source: GeoPoint(
                latitude: orderModel.value.sourceLocationLAtLng?.latitude ?? 0,
                longitude:
                    orderModel.value.sourceLocationLAtLng?.longitude ?? 0),
            destination: GeoPoint(
                latitude:
                    orderModel.value.destinationLocationLAtLng?.latitude ?? 0,
                longitude:
                    orderModel.value.destinationLocationLAtLng?.longitude ??
                        0));
      } else {
        AppLogger.warning(
            "Source or destination coordinates are null for OSM polyline.",
            tag: "OrderMapController");
      }
    } catch (e) {
      AppLogger.error('Error drawing OSM polyline: $e',
          tag: "OrderMapController", error: e);
    }
  }

  Future<void> updateCameraLocation(
      {required GeoPoint source, required GeoPoint destination}) async {
    AppLogger.debug(
        "updateCameraLocation (OSM) called with source: $source, destination: $destination",
        tag: "OrderMapController");
    BoundingBox bounds;

    if (source.latitude > destination.latitude &&
        source.longitude > destination.longitude) {
      bounds = BoundingBox(
        north: source.latitude,
        south: destination.latitude,
        east: source.longitude,
        west: destination.longitude,
      );
    } else if (source.longitude > destination.longitude) {
      bounds = BoundingBox(
        north: destination.latitude,
        south: source.latitude,
        east: source.longitude,
        west: destination.longitude,
      );
    } else if (source.latitude > destination.latitude) {
      bounds = BoundingBox(
        north: source.latitude,
        south: destination.latitude,
        east: destination.longitude,
        west: source.longitude,
      );
    } else {
      bounds = BoundingBox(
        north: destination.latitude,
        south: source.latitude,
        east: destination.longitude,
        west: source.longitude,
      );
    }
    AppLogger.debug("Calculated OSM BoundingBox: $bounds",
        tag: "OrderMapController");
    await mapOsmController.zoomToBoundingBox(bounds, paddinInPixel: 300);
    AppLogger.info("OSM map zoomed to bounding box.",
        tag: "OrderMapController");
  }

  Future<void> setOsmMarker(
      {required GeoPoint departure, required GeoPoint destination}) async {
    AppLogger.debug(
        "setOsmMarker called with departure: $departure, destination: $destination",
        tag: "OrderMapController");
    if (osmMarkers.containsKey('Source')) {
      await mapOsmController.removeMarker(osmMarkers['Source']!);
      AppLogger.debug("Removed existing 'Source' OSM marker.",
          tag: "OrderMapController");
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await mapOsmController
          .addMarker(departure,
              markerIcon: MarkerIcon(iconWidget: departureOsmIcon),
              angle: pi / 3,
              iconAnchor: IconAnchor(
                anchor: Anchor.top,
              ))
          .then((v) {
        osmMarkers['Source'] = departure;
        AppLogger.info("'Source' OSM marker added at $departure.",
            tag: "OrderMapController");
      }).catchError((error) {
        AppLogger.error("Error adding 'Source' OSM marker: $error",
            tag: "OrderMapController", error: error);
      });

      if (osmMarkers.containsKey('Destination')) {
        await mapOsmController.removeMarker(osmMarkers['Destination']!);
        AppLogger.debug("Removed existing 'Destination' OSM marker.",
            tag: "OrderMapController");
      }

      await mapOsmController
          .addMarker(destination,
              markerIcon: MarkerIcon(iconWidget: destinationOsmIcon),
              angle: pi / 3,
              iconAnchor: IconAnchor(
                anchor: Anchor.top,
              ))
          .then((v) {
        osmMarkers['Destination'] = destination;
        AppLogger.info("'Destination' OSM marker added at $destination.",
            tag: "OrderMapController");
      }).catchError((error) {
        AppLogger.error("Error adding 'Destination' OSM marker: $error",
            tag: "OrderMapController", error: error);
      });
    });
  }
}
