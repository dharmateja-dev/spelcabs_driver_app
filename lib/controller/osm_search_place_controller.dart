import 'dart:developer';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

class OsmSearchPlaceController extends GetxController with GetSingleTickerProviderStateMixin {
  Rx<TextEditingController> searchTxtController = TextEditingController().obs;
  RxList<SearchInfo> suggestionsList = <SearchInfo>[].obs;
  Timer? _debounce;
  RxString errorMessage = "".obs;

  // Map controller
  late MapController mapController;

  // Selected location
  Rx<SearchInfo?> selectedLocation = Rx<SearchInfo?>(null);
  RxBool isLocationSelected = false.obs;
  RxBool isLoading = false.obs;
  RxBool showSuggestions = true.obs;

  // Animation controller for bottom sheet
  late AnimationController animationController;
  late Animation<double> animation;

  @override
  void onInit() {
    super.onInit();

    // Initialize animation controller
    animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );

    // Initialize map controller
    mapController = MapController(
      initMapWithUserPosition: const UserTrackingOption(
        enableTracking: true,
        unFollowUser: false,
      ),
    );

    // Set up search listener
    searchTxtController.value.addListener(() {
      _onChanged();
    });
  }

  @override
  void onClose() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    animationController.dispose();
    mapController.dispose();
    super.onClose();
  }

  // Robust address search method based on working implementation
  Future<void> customAddressSearch(String query) async {
    isLoading.value = true;
    errorMessage.value = "";
    suggestionsList.clear();

    try {
      final List<SearchInfo> results = await addressSuggestion(
        query,
        limitInformation: 5,
        locale: "en", // This was the missing key parameter!
      );

      if (results.isNotEmpty) {
        suggestionsList.value = results;
        showSuggestions.value = true;
      } else {
        errorMessage.value = "No results found.";
        showSuggestions.value = false;
      }
    } on DioException catch (e) {
      log("DioException during address search: ${e.message}");
      errorMessage.value = "Network error: ${e.message}";
      showSuggestions.value = false;
    } catch (e, s) {
      log("Error during address search: $e", stackTrace: s);
      errorMessage.value = "An unknown error occurred. Please try again.";
      showSuggestions.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  void _onChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final text = searchTxtController.value.text.trim();

      if (text.isNotEmpty && text.length > 2) {
        await customAddressSearch(text);
      } else {
        suggestionsList.clear();
        errorMessage.value = "";
        showSuggestions.value = false;
      }
    });
  }

  // Select location from suggestions
  void selectLocationFromSuggestion(SearchInfo suggestion) async {
    try {
      selectedLocation.value = suggestion;
      isLocationSelected.value = true;
      showSuggestions.value = false;
      searchTxtController.value.text = suggestion.address?.toString() ?? '';

      // Move map to selected location using correct method
      if (suggestion.point != null) {
        final geoPoint = GeoPoint(
          latitude: suggestion.point!.latitude,
          longitude: suggestion.point!.longitude,
        );

        await mapController.moveTo(geoPoint, animate: true);
        await mapController.setZoom(zoomLevel: 15.0);

        // Clear existing markers and add new one
        await mapController.clearAllRoads();
        await mapController.addMarker(
          geoPoint,
          markerIcon: const MarkerIcon(
            icon: Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40,
            ),
          ),
        );
      }

      // Show bottom card
      animationController.forward();

    } catch (e, s) {
      log("Error selecting location: $e", stackTrace: s);
      errorMessage.value = "Failed to select location.";
    }
  }

  // Handle map tap
  void onMapTap(GeoPoint position) async {
    try {
      isLoading.value = true;

      // Create SearchInfo for tapped location
      SearchInfo locationInfo = SearchInfo(
        point: position,
        address: null, // Will show coordinates in UI
      );

      selectedLocation.value = locationInfo;
      isLocationSelected.value = true;
      showSuggestions.value = false;

      // Clear existing markers and add new one
      await mapController.clearAllRoads();
      await mapController.addMarker(
        position,
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );

      // Animate to show bottom card
      animationController.forward();

      log("Selected location via map tap: ${position.latitude}, ${position.longitude}");

    } catch (e, s) {
      log("Error in map tap handling: $e", stackTrace: s);
      errorMessage.value = "Failed to select location from map.";
    } finally {
      isLoading.value = false;
    }
  }

  // Clear selection
  void clearSelection() {
    selectedLocation.value = null;
    isLocationSelected.value = false;
    animationController.reverse();
    mapController.clearAllRoads();
    errorMessage.value = "";
  }

  // Confirm selection
  void confirmSelection() {
    if (selectedLocation.value != null) {
      Get.back(result: selectedLocation.value);
    }
  }

  // Get current location
  void getCurrentLocation() async {
    try {
      isLoading.value = true;

      // Move to user's current location
      await mapController.currentLocation();

      // Get current position
      GeoPoint? currentPosition = await mapController.myLocation();

      onMapTap(currentPosition);
        } catch (e, s) {
      log("Error getting current location: $e", stackTrace: s);
      errorMessage.value = "Failed to get current location.";
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to get display address
  String getDisplayAddress() {
    if (selectedLocation.value == null) return 'Unknown location';

    if (selectedLocation.value!.address != null) {
      return selectedLocation.value!.address.toString();
    }

    // Fallback to coordinates if no address
    if (selectedLocation.value!.point != null) {
      return 'Location: ${selectedLocation.value!.point!.latitude.toStringAsFixed(4)}, ${selectedLocation.value!.point!.longitude.toStringAsFixed(4)}';
    }

    return 'Unknown location';
  }
}