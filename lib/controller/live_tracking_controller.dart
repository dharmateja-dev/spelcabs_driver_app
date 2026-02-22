import 'dart:async';
import 'dart:math';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/intercity_order_model.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:driver/utils/app_logger.dart';

class LiveTrackingController extends GetxController {
  GoogleMapController? mapController;

  /// Stream subscriptions for proper cleanup
  StreamSubscription? _orderSubscription;
  StreamSubscription? _driverSubscription;
  StreamSubscription? _intercityOrderSubscription;
  StreamSubscription? _intercityDriverSubscription;

  @override
  void onInit() {
    AppLogger.debug("LiveTrackingController onInit called.",
        tag: "LiveTrackingController");
    if (Constant.selectedMapType == 'osm') {
      ShowToastDialog.showLoader("Please wait");
      mapOsmController = MapController(
          initPosition: GeoPoint(latitude: 20.9153, longitude: -100.7439),
          useExternalTracking: false); //OSM
      AppLogger.info("OSM map controller initialized.",
          tag: "LiveTrackingController");
    }
    addMarkerSetup();
    getArgument();
    // playSound();
    super.onInit();
  }

  @override
  void onClose() {
    AppLogger.debug("LiveTrackingController onClose called.",
        tag: "LiveTrackingController");
    _orderSubscription?.cancel();
    _driverSubscription?.cancel();
    _intercityOrderSubscription?.cancel();
    _intercityDriverSubscription?.cancel();
    ShowToastDialog.closeLoader();
    super.onClose();
  }

  Rx<DriverUserModel> driverUserModel = DriverUserModel().obs;
  Rx<OrderModel> orderModel = OrderModel().obs;
  Rx<InterCityOrderModel> intercityOrderModel = InterCityOrderModel().obs;

  RxBool isLoading = true.obs;
  RxString type = "".obs;

  Future<void> getArgument() async {
    AppLogger.debug("getArgument called.", tag: "LiveTrackingController");
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      type.value = argumentData['type'];
      AppLogger.info("Argument type: ${type.value}",
          tag: "LiveTrackingController");

      if (type.value == "orderModel") {
        OrderModel argumentOrderModel = argumentData['orderModel'];
        AppLogger.info("Fetching OrderModel with ID: ${argumentOrderModel.id}",
            tag: "LiveTrackingController");
        _orderSubscription = FireStoreUtils.fireStore
            .collection(CollectionName.orders)
            .doc(argumentOrderModel.id)
            .snapshots()
            .listen((event) {
          if (event.data() != null) {
            OrderModel orderModelStream = OrderModel.fromJson(event.data()!);
            orderModel.value = orderModelStream;
            AppLogger.info(
                "OrderModel stream updated: ${orderModel.value.id}, Status: ${orderModel.value.status}",
                tag: "LiveTrackingController");

            _driverSubscription = FireStoreUtils.fireStore
                .collection(CollectionName.driverUsers)
                .doc(argumentOrderModel.driverId)
                .snapshots()
                .listen((event) {
              if (event.data() != null) {
                driverUserModel.value = DriverUserModel.fromJson(event.data()!);
                AppLogger.info(
                    "DriverUserModel stream updated: ${driverUserModel.value.id}",
                    tag: "LiveTrackingController");

                if (Constant.selectedMapType != 'osm') {
                  if (orderModel.value.status == Constant.rideInProgress) {
                    getPolyline(
                        sourceLatitude:
                            driverUserModel.value.location!.latitude,
                        sourceLongitude:
                            driverUserModel.value.location!.longitude,
                        destinationLatitude: orderModel
                            .value.destinationLocationLAtLng!.latitude,
                        destinationLongitude: orderModel
                            .value.destinationLocationLAtLng!.longitude);
                    AppLogger.debug(
                        "Getting polyline for Google Maps (ride in progress).",
                        tag: "LiveTrackingController");
                  } else {
                    getPolyline(
                        sourceLatitude:
                            driverUserModel.value.location!.latitude,
                        sourceLongitude:
                            driverUserModel.value.location!.longitude,
                        destinationLatitude:
                            orderModel.value.sourceLocationLAtLng!.latitude,
                        destinationLongitude:
                            orderModel.value.sourceLocationLAtLng!.longitude);
                    AppLogger.debug(
                        "Getting polyline for Google Maps (ride active).",
                        tag: "LiveTrackingController");
                  }
                } else {
                  if (orderModel.value.status == Constant.rideInProgress) {
                    setOsmMarker(
                      departure: GeoPoint(
                          latitude:
                              orderModel.value.sourceLocationLAtLng?.latitude ??
                                  0.0,
                          longitude: orderModel
                                  .value.sourceLocationLAtLng?.longitude ??
                              0.0),
                      destination: GeoPoint(
                          latitude: orderModel
                                  .value.destinationLocationLAtLng?.latitude ??
                              0.0,
                          longitude: orderModel
                                  .value.destinationLocationLAtLng?.longitude ??
                              0.0),
                    );
                    AppLogger.debug("Setting OSM markers (ride in progress).",
                        tag: "LiveTrackingController");
                  } else {
                    setOsmMarker(
                      departure: GeoPoint(
                          latitude:
                              orderModel.value.sourceLocationLAtLng?.latitude ??
                                  0.0,
                          longitude: orderModel
                                  .value.sourceLocationLAtLng?.longitude ??
                              0.0),
                      destination: GeoPoint(
                          latitude:
                              orderModel.value.sourceLocationLAtLng!.latitude ??
                                  0.0,
                          longitude: orderModel
                                  .value.sourceLocationLAtLng!.longitude ??
                              0.0),
                    );
                    AppLogger.debug("Setting OSM markers (ride active).",
                        tag: "LiveTrackingController");
                  }
                }
              } else {
                AppLogger.warning(
                    "Driver user document not found in LiveTrackingController stream.",
                    tag: "LiveTrackingController");
              }
            }, onError: (error) {
              AppLogger.error(
                  "Error fetching driver user in LiveTrackingController stream: $error",
                  tag: "LiveTrackingController",
                  error: error);
            });

            if (orderModel.value.status == Constant.rideComplete) {
              Get.back();
              AppLogger.info("Order complete, navigating back.",
                  tag: "LiveTrackingController");
            }
          } else {
            AppLogger.warning(
                "Order document not found in LiveTrackingController stream for ID: ${argumentOrderModel.id}",
                tag: "LiveTrackingController");
          }
        }, onError: (error) {
          AppLogger.error(
              "Error fetching order in LiveTrackingController stream: $error",
              tag: "LiveTrackingController",
              error: error);
        });
      } else {
        InterCityOrderModel argumentOrderModel =
            argumentData['interCityOrderModel'];
        AppLogger.info(
            "Fetching InterCityOrderModel with ID: ${argumentOrderModel.id}",
            tag: "LiveTrackingController");
        _intercityOrderSubscription = FireStoreUtils.fireStore
            .collection(CollectionName.ordersIntercity)
            .doc(argumentOrderModel.id)
            .snapshots()
            .listen((event) {
          if (event.data() != null) {
            InterCityOrderModel orderModelStream =
                InterCityOrderModel.fromJson(event.data()!);
            intercityOrderModel.value = orderModelStream;
            AppLogger.info(
                "InterCityOrderModel stream updated: ${intercityOrderModel.value.id}, Status: ${intercityOrderModel.value.status}",
                tag: "LiveTrackingController");

            _intercityDriverSubscription = FireStoreUtils.fireStore
                .collection(CollectionName.driverUsers)
                .doc(argumentOrderModel.driverId)
                .snapshots()
                .listen((event) {
              if (event.data() != null) {
                driverUserModel.value = DriverUserModel.fromJson(event.data()!);
                AppLogger.info(
                    "DriverUserModel stream updated for intercity order: ${driverUserModel.value.id}",
                    tag: "LiveTrackingController");

                if (Constant.selectedMapType != 'osm') {
                  if (intercityOrderModel.value.status ==
                      Constant.rideInProgress) {
                    getPolyline(
                        sourceLatitude:
                            driverUserModel.value.location!.latitude,
                        sourceLongitude:
                            driverUserModel.value.location!.longitude,
                        destinationLatitude: intercityOrderModel
                            .value.destinationLocationLAtLng!.latitude,
                        destinationLongitude: intercityOrderModel
                            .value.destinationLocationLAtLng!.longitude);
                    AppLogger.debug(
                        "Getting polyline for Google Maps (intercity ride in progress).",
                        tag: "LiveTrackingController");
                  } else {
                    getPolyline(
                        sourceLatitude:
                            driverUserModel.value.location!.latitude,
                        sourceLongitude:
                            driverUserModel.value.location!.longitude,
                        destinationLatitude: intercityOrderModel
                            .value.sourceLocationLAtLng!.latitude,
                        destinationLongitude: intercityOrderModel
                            .value.sourceLocationLAtLng!.longitude);
                    AppLogger.debug(
                        "Getting polyline for Google Maps (intercity ride active).",
                        tag: "LiveTrackingController");
                  }
                } else {
                  if (orderModel.value.status == Constant.rideInProgress) {
                    setOsmMarker(
                      departure: GeoPoint(
                        latitude: intercityOrderModel
                                .value.sourceLocationLAtLng!.latitude ??
                            0.0,
                        longitude: intercityOrderModel
                                .value.sourceLocationLAtLng!.longitude ??
                            0.0,
                      ),
                      destination: GeoPoint(
                          latitude: intercityOrderModel
                                  .value.destinationLocationLAtLng!.latitude ??
                              0.0,
                          longitude: intercityOrderModel
                                  .value.destinationLocationLAtLng!.longitude ??
                              0.0),
                    );
                    AppLogger.debug(
                        "Setting OSM markers (intercity ride in progress).",
                        tag: "LiveTrackingController");
                  } else {
                    setOsmMarker(
                      departure: GeoPoint(
                        latitude: intercityOrderModel
                                .value.sourceLocationLAtLng!.latitude ??
                            0.0,
                        longitude: intercityOrderModel
                                .value.sourceLocationLAtLng!.longitude ??
                            0.0,
                      ),
                      destination: GeoPoint(
                        latitude: intercityOrderModel
                                .value.sourceLocationLAtLng!.latitude ??
                            0.0,
                        longitude: intercityOrderModel
                                .value.sourceLocationLAtLng!.longitude ??
                            0.0,
                      ),
                    );
                    AppLogger.debug(
                        "Setting OSM markers (intercity ride active).",
                        tag: "LiveTrackingController");
                  }
                }
              } else {
                AppLogger.warning(
                    "Driver user document not found in LiveTrackingController stream for intercity order.",
                    tag: "LiveTrackingController");
              }
            }, onError: (error) {
              AppLogger.error(
                  "Error fetching driver user in LiveTrackingController stream for intercity order: $error",
                  tag: "LiveTrackingController",
                  error: error);
            });

            if (intercityOrderModel.value.status == Constant.rideComplete) {
              Get.back();
              AppLogger.info("Intercity order complete, navigating back.",
                  tag: "LiveTrackingController");
            }
          } else {
            AppLogger.warning(
                "Intercity order document not found in LiveTrackingController stream for ID: ${argumentOrderModel.id}",
                tag: "LiveTrackingController");
          }
        }, onError: (error) {
          AppLogger.error(
              "Error fetching intercity order in LiveTrackingController stream: $error",
              tag: "LiveTrackingController",
              error: error);
        });
      }
    } else {
      AppLogger.warning("No arguments received for LiveTrackingController.",
          tag: "LiveTrackingController");
    }
    isLoading.value = false;
    update();
    AppLogger.debug("LiveTrackingController isLoading set to false.",
        tag: "LiveTrackingController");
  }

  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? driverIcon;

  void getPolyline(
      {required double? sourceLatitude,
      required double? sourceLongitude,
      required double? destinationLatitude,
      required double? destinationLongitude}) async {
    AppLogger.debug(
        "getPolyline called with source: ($sourceLatitude, $sourceLongitude), destination: ($destinationLatitude, $destinationLongitude)",
        tag: "LiveTrackingController");
    if (sourceLatitude != null &&
        sourceLongitude != null &&
        destinationLatitude != null &&
        destinationLongitude != null) {
      List<LatLng> polylineCoordinates = [];
      PolylineRequest polylineRequest = PolylineRequest(
        origin: PointLatLng(sourceLatitude, sourceLongitude),
        destination: PointLatLng(destinationLatitude, destinationLongitude),
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
              tag: "LiveTrackingController");
        } else {
          AppLogger.warning("No polyline points found: ${result.errorMessage}",
              tag: "LiveTrackingController");
        }
      } catch (e, s) {
        AppLogger.error("Error getting route between coordinates: $e",
            tag: "LiveTrackingController", error: e, stackTrace: s);
      }

      if (type.value == "orderModel") {
        addMarker(
            latitude: orderModel.value.sourceLocationLAtLng!.latitude,
            longitude: orderModel.value.sourceLocationLAtLng!.longitude,
            id: "Departure",
            descriptor: departureIcon!,
            rotation: 0.0);
        addMarker(
            latitude: orderModel.value.destinationLocationLAtLng!.latitude,
            longitude: orderModel.value.destinationLocationLAtLng!.longitude,
            id: "Destination",
            descriptor: destinationIcon!,
            rotation: 0.0);
        addMarker(
            latitude: driverUserModel.value.location!.latitude,
            longitude: driverUserModel.value.location!.longitude,
            id: "Driver",
            descriptor: driverIcon!,
            rotation: driverUserModel.value.rotation);
        AppLogger.debug("Markers added for OrderModel.",
            tag: "LiveTrackingController");

        _addPolyLine(polylineCoordinates);
      } else {
        addMarker(
            latitude: intercityOrderModel.value.sourceLocationLAtLng!.latitude,
            longitude:
                intercityOrderModel.value.sourceLocationLAtLng!.longitude,
            id: "Departure",
            descriptor: departureIcon!,
            rotation: 0.0);
        addMarker(
            latitude:
                intercityOrderModel.value.destinationLocationLAtLng!.latitude,
            longitude:
                intercityOrderModel.value.destinationLocationLAtLng!.longitude,
            id: "Destination",
            descriptor: destinationIcon!,
            rotation: 0.0);
        addMarker(
            latitude: driverUserModel.value.location!.latitude,
            longitude: driverUserModel.value.location!.longitude,
            id: "Driver",
            descriptor: driverIcon!,
            rotation: driverUserModel.value.rotation);
        AppLogger.debug("Markers added for InterCityOrderModel.",
            tag: "LiveTrackingController");

        _addPolyLine(polylineCoordinates);
      }
    } else {
      AppLogger.warning(
          "Cannot get polyline: source or destination coordinates are null.",
          tag: "LiveTrackingController");
    }
  }

  RxMap<MarkerId, Marker> markers = <MarkerId, Marker>{}.obs;

  void addMarker(
      {required double? latitude,
      required double? longitude,
      required String id,
      required BitmapDescriptor descriptor,
      required double? rotation}) {
    MarkerId markerId = MarkerId(id);
    Marker marker = Marker(
        markerId: markerId,
        icon: descriptor,
        position: LatLng(latitude ?? 0.0, longitude ?? 0.0),
        rotation: rotation ?? 0.0);
    markers[markerId] = marker;
    AppLogger.debug("Marker added: $id at ($latitude, $longitude)",
        tag: "LiveTrackingController");
  }

  Future<void> addMarkerSetup() async {
    AppLogger.debug("addMarkerSetup called.", tag: "LiveTrackingController");
    try {
      if (Constant.selectedMapType == 'google') {
        final Uint8List departure =
            await Constant().getBytesFromAsset('assets/images/pickup.png', 100);
        final Uint8List destination = await Constant()
            .getBytesFromAsset('assets/images/dropoff.png', 100);
        final Uint8List driver =
            await Constant().getBytesFromAsset('assets/images/ic_cab.png', 50);
        departureIcon = BitmapDescriptor.fromBytes(departure);
        destinationIcon = BitmapDescriptor.fromBytes(destination);
        driverIcon = BitmapDescriptor.fromBytes(driver);
        AppLogger.info("Google Maps marker icons loaded.",
            tag: "LiveTrackingController");
      } else {
        departureOsmIcon = Image.asset("assets/images/pickup.png",
            width: 30, height: 30); //OSM
        destinationOsmIcon = Image.asset("assets/images/dropoff.png",
            width: 30, height: 30); //OSM
        driverOsmIcon = Image.asset("assets/images/ic_cab.png",
            width: 80, height: 80); //OSM
        AppLogger.info("OSM marker icons loaded.",
            tag: "LiveTrackingController");
      }
    } catch (e, s) {
      AppLogger.error("Error setting up marker icons: $e",
          tag: "LiveTrackingController", error: e, stackTrace: s);
    }
  }

  RxMap<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{}.obs;
  PolylinePoints polylinePoints = PolylinePoints();

  void _addPolyLine(List<LatLng> polylineCoordinates) {
    AppLogger.debug(
        "_addPolyLine called with ${polylineCoordinates.length} points.",
        tag: "LiveTrackingController");
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      points: polylineCoordinates,
      consumeTapEvents: true,
      startCap: Cap.roundCap,
      width: 6,
    );
    polyLines[id] = polyline;
    AppLogger.info("Polyline added to map.", tag: "LiveTrackingController");
    updateCameraLocation(
        polylineCoordinates.first, polylineCoordinates.last, mapController);
  }

  Future<void> updateCameraLocation(
    LatLng source,
    LatLng destination,
    GoogleMapController? mapController,
  ) async {
    AppLogger.debug(
        "updateCameraLocation (Google Maps) called with source: $source, destination: $destination",
        tag: "LiveTrackingController");
    if (mapController == null) {
      AppLogger.warning("mapController is null, cannot update camera location.",
          tag: "LiveTrackingController");
      return;
    }

    LatLngBounds bounds;

    if (source.latitude > destination.latitude &&
        source.longitude > destination.longitude) {
      bounds = LatLngBounds(southwest: destination, northeast: source);
    } else if (source.longitude > destination.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(source.latitude, destination.longitude),
          northeast: LatLng(destination.latitude, source.longitude));
    } else if (source.latitude > destination.latitude) {
      bounds = LatLngBounds(
          southwest: LatLng(destination.latitude, source.longitude),
          northeast: LatLng(source.latitude, destination.longitude));
    } else {
      bounds = LatLngBounds(southwest: source, northeast: destination);
    }
    AppLogger.debug("Calculated LatLngBounds: $bounds",
        tag: "LiveTrackingController");

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 10);

    return checkCameraLocation(cameraUpdate, mapController);
  }

  Future<void> checkCameraLocation(
      CameraUpdate cameraUpdate, GoogleMapController mapController, {int retries = 0}) async {
    if (retries > 5) {
      AppLogger.warning("checkCameraLocation: max retries reached, aborting.",
          tag: "LiveTrackingController");
      return; // Safety limit to prevent infinite recursion
    }
    AppLogger.debug("checkCameraLocation called (retry $retries).",
        tag: "LiveTrackingController");
    mapController.animateCamera(cameraUpdate);
    LatLngBounds l1 = await mapController.getVisibleRegion();
    LatLngBounds l2 = await mapController.getVisibleRegion();
    AppLogger.debug("Visible region 1: $l1, Visible region 2: $l2",
        tag: "LiveTrackingController");

    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      AppLogger.warning("Camera location not updated correctly, retrying.",
          tag: "LiveTrackingController");
      await Future.delayed(const Duration(milliseconds: 200));
      return checkCameraLocation(cameraUpdate, mapController, retries: retries + 1);
    }
  }

  //OSM
  late MapController mapOsmController;
  Rx<RoadInfo> roadInfo = RoadInfo().obs;
  Map<String, GeoPoint> osmMarkers = <String, GeoPoint>{};
  Image? departureOsmIcon; //OSM
  Image? destinationOsmIcon; //OSM
  Image? driverOsmIcon;

  void getOSMPolyline(GeoPoint location, bool themeChange) async {
    AppLogger.debug(
        "getOSMPolyline called with location: $location, themeChange: $themeChange",
        tag: "LiveTrackingController");
    try {
      GeoPoint destinationLocation;
      if (type.value == "orderModel") {
        if (orderModel.value.status == Constant.rideInProgress) {
          destinationLocation = GeoPoint(
              latitude:
                  orderModel.value.destinationLocationLAtLng!.latitude ?? 0,
              longitude:
                  orderModel.value.destinationLocationLAtLng!.longitude ?? 0);
          AppLogger.debug(
              "OSM destination for order (in progress): $destinationLocation",
              tag: "LiveTrackingController");
        } else {
          destinationLocation = GeoPoint(
              latitude: orderModel.value.sourceLocationLAtLng!.latitude ?? 0,
              longitude: orderModel.value.sourceLocationLAtLng!.longitude ?? 0);
          AppLogger.debug(
              "OSM destination for order (active): $destinationLocation",
              tag: "LiveTrackingController");
        }
      } else {
        if (type.value == "orderModel") {
          // This condition seems redundant, might be a copy-paste error. Assuming it should be intercity.
          destinationLocation = GeoPoint(
              latitude: intercityOrderModel
                      .value.destinationLocationLAtLng!.latitude ??
                  0,
              longitude: intercityOrderModel
                      .value.destinationLocationLAtLng!.longitude ??
                  0);
          AppLogger.debug(
              "OSM destination for intercity order (in progress): $destinationLocation",
              tag: "LiveTrackingController");
        } else {
          destinationLocation = GeoPoint(
              latitude:
                  intercityOrderModel.value.sourceLocationLAtLng!.latitude ?? 0,
              longitude:
                  intercityOrderModel.value.sourceLocationLAtLng!.longitude ??
                      0);
          AppLogger.debug(
              "OSM destination for intercity order (active): $destinationLocation",
              tag: "LiveTrackingController");
        }
      }
      if (orderModel.value.destinationLocationLAtLng != null) {
        await mapOsmController.removeLastRoad();
        roadInfo.value = await mapOsmController.drawRoad(
          GeoPoint(latitude: location.latitude, longitude: location.longitude),
          destinationLocation,
          roadType: RoadType.car,
          roadOption: RoadOption(
            roadWidth: 15,
            roadColor:
                themeChange ? AppColors.darkModePrimary : AppColors.primary,
            zoomInto: false,
          ),
        );
        AppLogger.info("OSM road drawn. RoadInfo: ${roadInfo.value.distance}m",
            tag: "LiveTrackingController");
        mapOsmController.moveTo(
          GeoPoint(latitude: location.latitude, longitude: location.longitude),
          animate: true,
        );
        AppLogger.debug("OSM map moved to current location.",
            tag: "LiveTrackingController");
      } else {
        AppLogger.warning("Destination location is null for OSM polyline.",
            tag: "LiveTrackingController");
      }
    } catch (e) {
      AppLogger.error('Error drawing OSM polyline: $e',
          tag: "LiveTrackingController", error: e);
    }
  }

  Future<void> updateOSMCameraLocation(
      {required GeoPoint source, required GeoPoint destination}) async {
    AppLogger.debug(
        "updateOSMCameraLocation called with source: $source, destination: $destination",
        tag: "LiveTrackingController");
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
        tag: "LiveTrackingController");
    await mapOsmController.zoomToBoundingBox(bounds, paddinInPixel: 100);
    AppLogger.info("OSM map zoomed to bounding box.",
        tag: "LiveTrackingController");
  }

  Future<void> setOsmMarker(
      {required GeoPoint departure, required GeoPoint destination}) async {
    AppLogger.debug(
        "setOsmMarker called with departure: $departure, destination: $destination",
        tag: "LiveTrackingController");
    if (osmMarkers.containsKey('Source')) {
      await mapOsmController.removeMarker(osmMarkers['Source']!);
      AppLogger.debug("Removed existing 'Source' OSM marker.",
          tag: "LiveTrackingController");
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
            tag: "LiveTrackingController");
      }).catchError((error) {
        AppLogger.error("Error adding 'Source' OSM marker: $error",
            tag: "LiveTrackingController", error: error);
      });

      if (osmMarkers.containsKey('Destination')) {
        await mapOsmController.removeMarker(osmMarkers['Destination']!);
        AppLogger.debug("Removed existing 'Destination' OSM marker.",
            tag: "LiveTrackingController");
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
            tag: "LiveTrackingController");
      }).catchError((error) {
        AppLogger.error("Error adding 'Destination' OSM marker: $error",
            tag: "LiveTrackingController", error: error);
      });
    });
  }
}
