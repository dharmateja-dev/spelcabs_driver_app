import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/send_notification.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/order_map_controller.dart';
import 'package:driver/model/order/driverId_accept_reject.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/app_logger.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/widget/location_view.dart';
import 'package:driver/widget/user_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class OrderMapScreen extends StatelessWidget {
  const OrderMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<OrderMapController>(
        init: OrderMapController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              leading: InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: const Icon(
                    Icons.arrow_back,
                  )),
            ),
            body: controller.isLoading.value
                ? Constant.loader(context)
                : Column(
                    children: [
                      Container(
                        height: Responsive.width(10, context),
                        width: Responsive.width(100, context),
                        color: AppColors.primary,
                      ),
                      Expanded(
                        child: Container(
                          transform: Matrix4.translationValues(0.0, -20.0, 0.0),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(25),
                                  topRight: Radius.circular(25))),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30)),
                            child: Stack(
                              children: [
                                Constant.selectedMapType == 'osm'
                                    ? OSMFlutter(
                                        controller: controller.mapOsmController,
                                        osmOption: const OSMOption(
                                          userTrackingOption:
                                              UserTrackingOption(
                                            enableTracking: false,
                                            unFollowUser: false,
                                          ),
                                          zoomOption: ZoomOption(
                                            initZoom: 12,
                                            minZoomLevel: 2,
                                            maxZoomLevel: 19,
                                            stepZoom: 1.0,
                                          ),
                                          roadConfiguration: RoadOption(
                                            roadColor: Colors.yellowAccent,
                                          ),
                                        ),
                                        onMapIsReady: (active) async {
                                          if (active) {
                                            controller.getOSMPolyline(
                                                themeChange.getThem());
                                            ShowToastDialog.closeLoader();
                                          }
                                        })
                                    : GoogleMap(
                                        myLocationEnabled: true,
                                        myLocationButtonEnabled: true,
                                        mapType: MapType.terrain,
                                        zoomControlsEnabled: false,
                                        polylines: Set<Polyline>.of(
                                            controller.polyLines.values),
                                        padding: const EdgeInsets.only(
                                          top: 22.0,
                                        ),
                                        markers: Set<Marker>.of(
                                            controller.markers.values),
                                        onMapCreated: (GoogleMapController
                                            mapController) {
                                          controller.mapController
                                              .complete(mapController);
                                        },
                                        initialCameraPosition: CameraPosition(
                                          zoom: 15,
                                          target: LatLng(
                                              Constant.currentLocation!
                                                      .latitude ??
                                                  45.521563,
                                              Constant.currentLocation!
                                                      .longitude ??
                                                  -122.677433),
                                        ),
                                      ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: themeChange.getThem()
                                            ? AppColors.darkContainerBackground
                                            : AppColors.containerBackground,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                        border: Border.all(
                                            color: themeChange.getThem()
                                                ? AppColors.darkContainerBorder
                                                : AppColors.containerBorder,
                                            width: 0.5),
                                        boxShadow: themeChange.getThem()
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.5),
                                                  blurRadius: 8,
                                                  offset: const Offset(0,
                                                      2), // changes position of shadow
                                                ),
                                              ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            UserView(
                                              userId: controller
                                                  .orderModel.value.userId,
                                              amount: controller
                                                  .orderModel.value.offerRate,
                                              distance: controller
                                                  .orderModel.value.distance,
                                              distanceType: controller
                                                  .orderModel
                                                  .value
                                                  .distanceType,
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 5),
                                              child: Divider(),
                                            ),
                                            LocationView(
                                              sourceLocation: controller
                                                  .orderModel
                                                  .value
                                                  .sourceLocationName
                                                  .toString(),
                                              destinationLocation: controller
                                                  .orderModel
                                                  .value
                                                  .destinationLocationName
                                                  .toString(),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Visibility(
                                              visible: controller
                                                      .orderModel
                                                      .value
                                                      .service!
                                                      .offerRate ==
                                                  true,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        if (double.parse(
                                                                controller
                                                                    .newAmount
                                                                    .value) >=
                                                            10) {
                                                          controller.newAmount
                                                              .value = (double.parse(
                                                                      controller
                                                                          .newAmount
                                                                          .value) -
                                                                  10)
                                                              .toString();

                                                          controller
                                                                  .enterOfferRateController
                                                                  .value
                                                                  .text =
                                                              controller
                                                                  .newAmount
                                                                  .value;
                                                        } else {
                                                          controller.newAmount
                                                              .value = "0";
                                                        }
                                                      },
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                            border: Border.all(
                                                                color: AppColors
                                                                    .textFieldBorder),
                                                            borderRadius:
                                                                const BorderRadius
                                                                    .all(
                                                                    Radius.circular(
                                                                        30))),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      30,
                                                                  vertical: 10),
                                                          child: Text(
                                                            "- 10",
                                                            style: GoogleFonts
                                                                .poppins(),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 20,
                                                    ),
                                                    Text(
                                                        Constant.amountShow(
                                                            amount: controller
                                                                .newAmount.value
                                                                .toString()),
                                                        style: GoogleFonts
                                                            .poppins()),
                                                    const SizedBox(
                                                      width: 20,
                                                    ),
                                                    ButtonThem.roundButton(
                                                      context,
                                                      title: "+ 10",
                                                      btnWidthRatio: 0.22,
                                                      onPress: () {
                                                        controller.newAmount
                                                            .value = (double.parse(
                                                                    controller
                                                                        .newAmount
                                                                        .value) +
                                                                10)
                                                            .toStringAsFixed(Constant
                                                                .currencyModel!
                                                                .decimalDigits!);
                                                        controller
                                                                .enterOfferRateController
                                                                .value
                                                                .text =
                                                            controller.newAmount
                                                                .value;
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Visibility(
                                              visible: controller
                                                      .orderModel
                                                      .value
                                                      .service!
                                                      .offerRate ==
                                                  true,
                                              child: TextFieldThem
                                                  .buildTextFiledWithPrefixIcon(
                                                context,
                                                hintText: "Enter Fare rate",
                                                controller: controller
                                                    .enterOfferRateController
                                                    .value,
                                                keyBoardType:
                                                    const TextInputType
                                                        .numberWithOptions(
                                                        decimal: true,
                                                        signed: false),
                                                onChanged: (value) {
                                                  if (value.isEmpty) {
                                                    controller.newAmount.value =
                                                        "0.0";
                                                  } else {
                                                    controller.newAmount.value =
                                                        value;
                                                  }
                                                },
                                                prefix: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 10),
                                                  child: Text(Constant
                                                      .currencyModel!.symbol
                                                      .toString()),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            ButtonThem.buildButton(
                                              context,
                                              title:
                                                  "Accept fare on ${Constant.amountShow(amount: controller.newAmount.value)}"
                                                      .tr,
                                              onPress: controller
                                                      .isAcceptingRide.value
                                                  ? null
                                                  : () async {
                                                      // Prevent multiple clicks
                                                      if (controller
                                                          .isAcceptingRide
                                                          .value) return;

                                                      try {
                                                        controller
                                                            .isAcceptingRide
                                                            .value = true;

                                                        // Show loader immediately to eliminate perceived lag
                                                        ShowToastDialog
                                                            .showLoader(
                                                                "Please wait"
                                                                    .tr);

                                                        bool hasActive =
                                                            await FireStoreUtils
                                                                .hasActiveRide();
                                                        if (hasActive) {
                                                          ShowToastDialog
                                                              .closeLoader();
                                                          ShowToastDialog.showToast(
                                                              "You already have an active ride. Please complete it before accepting a new one."
                                                                  .tr);
                                                          controller
                                                              .isAcceptingRide
                                                              .value = false;
                                                          return;
                                                        }

                                                        // Validate amount is not less than 90% of recommended
                                                        double
                                                            recommendedAmount =
                                                            double.tryParse(controller
                                                                    .orderModel
                                                                    .value
                                                                    .offerRate
                                                                    .toString()) ??
                                                                0.0;
                                                        double enteredAmount =
                                                            double.tryParse(
                                                                    controller
                                                                        .newAmount
                                                                        .value) ??
                                                                0.0;
                                                        if (enteredAmount <
                                                            recommendedAmount *
                                                                0.9) {
                                                          ShowToastDialog
                                                              .closeLoader();
                                                          ShowToastDialog.showToast(
                                                              "Your offer cannot be less than 90% of the recommended price."
                                                                  .tr);
                                                          controller
                                                              .isAcceptingRide
                                                              .value = false;
                                                          return;
                                                        }
                                                        // Prevent accepting new city rides if there are completed rides with pending payment
                                                        try {
                                                          final pendingPaymentsSnap = await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  CollectionName
                                                                      .orders)
                                                              .where('driverId',
                                                                  isEqualTo:
                                                                      FireStoreUtils
                                                                          .getCurrentUid())
                                                              .where('status',
                                                                  isEqualTo:
                                                                      Constant
                                                                          .rideComplete)
                                                              .where(
                                                                  'paymentStatus',
                                                                  isEqualTo:
                                                                      false)
                                                              .get();

                                                          if (pendingPaymentsSnap
                                                              .docs
                                                              .isNotEmpty) {
                                                            ShowToastDialog
                                                                .closeLoader();
                                                            ShowToastDialog
                                                                .showToast(
                                                                    "Please complete pending payments before accepting new rides"
                                                                        .tr);
                                                            return;
                                                          }
                                                        } catch (e) {
                                                          // If the check fails for any reason, allow the normal path but log the error
                                                          AppLogger.error(
                                                              "Error checking pending payments: $e",
                                                              tag:
                                                                  "OrderMapScreen");
                                                        }

                                                        // Existing wallet minimum check
                                                        if (double.parse(controller
                                                                .driverModel
                                                                .value
                                                                .walletAmount
                                                                .toString()) >=
                                                            double.parse(Constant
                                                                .minimumAmountToWithdrawal)) {
                                                          List<dynamic>
                                                              newAcceptedDriverId =
                                                              [];
                                                          if (controller
                                                                  .orderModel
                                                                  .value
                                                                  .acceptedDriverId !=
                                                              null) {
                                                            newAcceptedDriverId =
                                                                controller
                                                                    .orderModel
                                                                    .value
                                                                    .acceptedDriverId!;
                                                          } else {
                                                            newAcceptedDriverId =
                                                                [];
                                                          }
                                                          newAcceptedDriverId
                                                              .add(FireStoreUtils
                                                                  .getCurrentUid());
                                                          controller
                                                                  .orderModel
                                                                  .value
                                                                  .acceptedDriverId =
                                                              newAcceptedDriverId;
                                                          await FireStoreUtils
                                                              .setOrder(
                                                                  controller
                                                                      .orderModel
                                                                      .value);

                                                          await FireStoreUtils
                                                                  .getCustomer(controller
                                                                      .orderModel
                                                                      .value
                                                                      .userId
                                                                      .toString())
                                                              .then(
                                                                  (value) async {
                                                            if (value != null) {
                                                              await SendNotification
                                                                  .sendOneNotification(
                                                                      token: value
                                                                          .fcmToken
                                                                          .toString(),
                                                                      title:
                                                                          'New Driver Bid'
                                                                              .tr,
                                                                      body: '${controller.driverModel.value.fullName} has offered ${Constant.amountShow(amount: controller.newAmount.value)} for your journey.🚗'
                                                                          .tr,
                                                                      payload: {
                                                                        'type':
                                                                            'driver_bid',
                                                                        'orderId': controller
                                                                            .orderModel
                                                                            .value
                                                                            .id
                                                                            .toString(),
                                                                      },
                                                                      driverName: controller
                                                                          .driverModel
                                                                          .value
                                                                          .fullName);
                                                            }
                                                          });

                                                          DriverIdAcceptReject
                                                              driverIdAcceptReject =
                                                              DriverIdAcceptReject(
                                                                  driverId:
                                                                      FireStoreUtils
                                                                          .getCurrentUid(),
                                                                  acceptedRejectTime:
                                                                      Timestamp
                                                                          .now(),
                                                                  offerAmount:
                                                                      controller
                                                                          .newAmount
                                                                          .value);
                                                          FireStoreUtils.acceptRide(
                                                                  controller
                                                                      .orderModel
                                                                      .value,
                                                                  driverIdAcceptReject)
                                                              .then((value) {
                                                            ShowToastDialog
                                                                .closeLoader();
                                                            ShowToastDialog
                                                                .showToast(
                                                                    "Ride Accepted"
                                                                        .tr);
                                                            Get.back(
                                                                result: true);
                                                          });
                                                        } else {
                                                          ShowToastDialog
                                                              .closeLoader();
                                                          ShowToastDialog.showToast(
                                                              "You have to minimum ${Constant.amountShow(amount: Constant.minimumDepositToRideAccept.toString())} wallet amount to Accept Order and place a bid"
                                                                  .tr);
                                                        }
                                                      } catch (e) {
                                                        print(
                                                            "Error in accepting order map fare: $e");
                                                        ShowToastDialog
                                                            .closeLoader();
                                                      } finally {
                                                        controller
                                                            .isAcceptingRide
                                                            .value = false;
                                                      }
                                                    },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        });
  }
}
