import 'package:driver/controller/osm_search_place_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:developer';

class OsmSearchPlacesApi extends StatelessWidget {
  const OsmSearchPlacesApi({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: OsmSearchPlaceController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor:
                themeChange.getThem() ? AppColors.darkBackground : Colors.white,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: AppColors.primary,
              leading: InkWell(
                onTap: () {
                  Get.back();
                },
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              title: const Text(
                'Select Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: controller.getCurrentLocation,
                  icon: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            body: Stack(
              children: [
                // Map
                OSMFlutter(
                  controller: controller.mapController,
                  osmOption: OSMOption(
                    userTrackingOption: const UserTrackingOption(
                      enableTracking: true,
                      unFollowUser: false,
                    ),
                    zoomOption: const ZoomOption(
                      initZoom: 15,
                      minZoomLevel: 3,
                      maxZoomLevel: 19,
                      stepZoom: 1.0,
                    ),
                    userLocationMarker: UserLocationMaker(
                      personMarker: const MarkerIcon(
                        icon: Icon(
                          Icons.location_history_rounded,
                          color: Colors.blue,
                          size: 48,
                        ),
                      ),
                      directionArrowMarker: const MarkerIcon(
                        icon: Icon(
                          Icons.double_arrow,
                          color: Colors.blue,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  onMapIsReady: (isReady) {
                    log("Map is ready: $isReady");
                  },
                  onLocationChanged: (myLocation) {
                    log("Location changed: $myLocation");
                  },
                  onGeoPointClicked: (geoPoint) {
                    log("GeoPoint clicked: $geoPoint");
                    controller.onMapTap(geoPoint);
                  },
                ),

                // Search bar overlay
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: themeChange.getThem()
                          ? AppColors.darkContainerBackground
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: controller.searchTxtController.value,
                      style: GoogleFonts.poppins(
                        color:
                            themeChange.getThem() ? Colors.white : Colors.black,
                      ),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 15),
                        border: InputBorder.none,
                        hintText: "Search your location here".tr,
                        hintStyle: GoogleFonts.poppins(
                          color:
                              themeChange.getThem() ? Colors.grey : Colors.grey,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color:
                              themeChange.getThem() ? Colors.grey : Colors.grey,
                        ),
                        suffixIcon: Obx(() => controller
                                .searchTxtController.value.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                color: themeChange.getThem()
                                    ? Colors.grey
                                    : Colors.grey,
                                onPressed: () {
                                  controller.searchTxtController.value.clear();
                                  controller.suggestionsList.clear();
                                  controller.showSuggestions.value = false;
                                },
                              )
                            : const SizedBox()),
                      ),
                      onTap: () {
                        if (controller.suggestionsList.isNotEmpty) {
                          controller.showSuggestions.value = true;
                        }
                      },
                    ),
                  ),
                ),

                // Search suggestions
                Obx(() => controller.showSuggestions.value &&
                        controller.suggestionsList.isNotEmpty
                    ? Positioned(
                        top: 80,
                        left: 10,
                        right: 10,
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          decoration: BoxDecoration(
                            color: themeChange.getThem()
                                ? AppColors.darkContainerBackground
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: controller.suggestionsList.length,
                            separatorBuilder: (context, index) => Divider(
                              color: themeChange.getThem()
                                  ? Colors.grey[700]
                                  : Colors.grey[300],
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              final suggestion =
                                  controller.suggestionsList[index];
                              return ListTile(
                                leading: Icon(
                                  Icons.location_on_outlined,
                                  color: themeChange.getThem()
                                      ? Colors.grey
                                      : Colors.grey[600],
                                ),
                                title: Text(
                                  suggestion.address?.toString() ??
                                      'Unknown location',
                                  style: GoogleFonts.poppins(
                                    color: themeChange.getThem()
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                onTap: () {
                                  controller
                                      .selectLocationFromSuggestion(suggestion);
                                },
                              );
                            },
                          ),
                        ),
                      )
                    : const SizedBox()),

                // Loading indicator
                Obx(() => controller.isLoading.value
                    ? Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                      )
                    : const SizedBox()),

                // Bottom location confirmation card
                Obx(() => controller.isLocationSelected.value
                    ? Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: AnimatedBuilder(
                          animation: controller.animation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                  0, (1 - controller.animation.value) * 200),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: themeChange.getThem()
                                      ? AppColors.darkContainerBackground
                                      : Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 10,
                                      offset: const Offset(0, -3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Handle bar
                                      Center(
                                        child: Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[400],
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 15),

                                      // Selected location info
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            color: AppColors.primary,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Selected Location',
                                                  style: GoogleFonts.poppins(
                                                    color: themeChange.getThem()
                                                        ? Colors.grey
                                                        : Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Text(
                                                  controller
                                                      .getDisplayAddress(),
                                                  style: GoogleFonts.poppins(
                                                    color: themeChange.getThem()
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 20),

                                      // Action buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed:
                                                  controller.clearSelection,
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                    color: AppColors.primary),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: Text(
                                                'Change',
                                                style: GoogleFonts.poppins(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            flex: 2,
                                            child: ElevatedButton(
                                              onPressed:
                                                  controller.confirmSelection,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primary,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Confirm Location',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : const SizedBox()),
              ],
            ),
          );
        });
  }
}
