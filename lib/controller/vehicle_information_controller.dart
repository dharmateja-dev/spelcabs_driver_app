import 'dart:async';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/model/driver_rules_model.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/vehicle_type_model.dart';
import 'package:driver/model/freight_vehicle.dart';
import 'package:driver/model/unified_vehicle_model.dart';
import 'package:driver/model/zone_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/model/language_name.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/utils/validation_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class VehicleInformationController extends GetxController {
  Rx<TextEditingController> vehicleNumberController =
      TextEditingController().obs;
  Rx<TextEditingController> seatsController = TextEditingController().obs;
  Rx<TextEditingController> registrationDateController =
      TextEditingController().obs;
  Rx<TextEditingController> driverRulesController = TextEditingController().obs;
  Rx<TextEditingController> zoneNameController = TextEditingController().obs;
  Rx<DateTime?> selectedDate = DateTime.now().obs;

  RxBool isLoading = true.obs;

  Rx<String> selectedColor = "".obs;
  List<String> carColorList = <String>[
    'Red',
    'Black',
    'White',
    'Blue',
    'Green',
    'Orange',
    'Silver',
    'Gray',
    'Yellow',
    'Brown',
    'Gold',
    'Beige',
    'Purple'
  ].obs;
  List<String> sheetList = <String>[
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15'
  ].obs;

  @override
  void onInit() {
    getVehicleType();
    super.onInit();
  }

  List<VehicleTypeModel> vehicleList = <VehicleTypeModel>[].obs;
  Rx<VehicleTypeModel> selectedVehicle = VehicleTypeModel().obs;
  var colors = [
    AppColors.serviceColor1,
    AppColors.serviceColor2,
    AppColors.serviceColor3,
  ];
  Rx<DriverUserModel> driverModel = DriverUserModel().obs;
  RxList<DriverRulesModel> driverRulesList = <DriverRulesModel>[].obs;
  RxList<DriverRulesModel> selectedDriverRulesList = <DriverRulesModel>[].obs;

  RxList<ServiceModel> serviceList = <ServiceModel>[].obs;
  RxList<ZoneModel> zoneList = <ZoneModel>[].obs;
  RxList selectedZone = <String>[].obs;

  Rx<String?> selectedServiceId = "".obs;
  RxString zoneString = "".obs;

  // Validation error state
  RxnString vehicleNumberError = RxnString(null);

  /// Validates the vehicle number synchronously (format validation only).
  /// Returns true if valid, false otherwise.
  bool validateVehicleNumber() {
    final error = ValidationUtils.validateVehicleNumber(
        vehicleNumberController.value.text);
    vehicleNumberError.value = error;
    return error == null;
  }

  /// Validates the vehicle number including async duplicate check.
  /// Returns true if valid and not a duplicate, false otherwise.
  Future<bool> validateVehicleNumberWithDuplicateCheck() async {
    // First do format validation
    if (!validateVehicleNumber()) {
      return false;
    }

    // Normalize the vehicle number for duplicate check
    final normalizedNumber = ValidationUtils.normalizeVehicleNumber(
        vehicleNumberController.value.text);

    // Check for duplicates
    final isDuplicate = await FireStoreUtils.checkVehicleNumberExists(
        normalizedNumber, driverModel.value.id);

    if (isDuplicate) {
      vehicleNumberError.value = 'This vehicle number is already registered';
      return false;
    }

    return true;
  }

  /// Normalizes the vehicle number to uppercase.
  /// Call this before saving to ensure consistent format.
  void normalizeVehicleNumber() {
    final currentText = vehicleNumberController.value.text;
    if (currentText.isNotEmpty) {
      final normalized = ValidationUtils.normalizeVehicleNumber(currentText);
      vehicleNumberController.value.text = normalized;
    }
  }

  // Check if vehicle information has been submitted
  bool get isVehicleInfoSubmitted =>
      driverModel.value.vehicleInformation != null;

  RxList<UnifiedVehicleModel> unifiedVehicleList = <UnifiedVehicleModel>[].obs;
  Rx<UnifiedVehicleModel?> selectedUnifiedVehicle =
      Rx<UnifiedVehicleModel?>(null);

  Future<void> getVehicleType() async {
    isLoading.value = true;
    unifiedVehicleList.clear(); // Clear list to avoid duplicates

    // Fetch Services (Passenger)
    await FireStoreUtils.getService().then((value) {
      serviceList.value = value;
    });

    // Fetch Freight
    List<FreightVehicle> freightList = await FireStoreUtils.getFreightVehicle();

    // Fetch Zones
    await FireStoreUtils.getZone().then((value) {
      if (value != null) {
        zoneList.value = value;
      }
    });

    // Merge Logic - Removed
    // Map<String, UnifiedVehicleModel> merger = {};

    // 1. Process Passenger Services
    for (var s in serviceList) {
      String name = Constant.localizationTitle(s.title).trim();
      unifiedVehicleList.add(UnifiedVehicleModel(
          name: name,
          image: s.image ?? "",
          passengerServiceId: s.id,
          rawNames: s.title
              ?.map((t) => LanguageName(name: t.title, type: t.type))
              .toList()));
    }

    // 2. Process Freight Vehicles
    for (var f in freightList) {
      String name = Constant.localizationName(f.name).trim();
      unifiedVehicleList.add(UnifiedVehicleModel(
          name: name,
          image: f.image ?? "",
          freightServiceId: f.id,
          rawNames: f.name));
    }

    // Fetch Driver Profile
    await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid())
        .then((value) {
      driverModel.value = value!;
      if (driverModel.value.vehicleInformation != null) {
        vehicleNumberController.value.text =
            driverModel.value.vehicleInformation!.vehicleNumber.toString();
        selectedDate.value =
            driverModel.value.vehicleInformation!.registrationDate!.toDate();
        registrationDateController.value.text =
            DateFormat("dd-MM-yyyy").format(selectedDate.value!);
        selectedColor.value =
            driverModel.value.vehicleInformation!.vehicleColor.toString();
        seatsController.value.text =
            driverModel.value.vehicleInformation!.seats ?? "2";
      }

      // Restore Zone Selection
      if (driverModel.value.zoneIds != null) {
        for (var element in driverModel.value.zoneIds!) {
          List<ZoneModel> list =
              zoneList.where((p0) => p0.id == element).toList();
          if (list.isNotEmpty) {
            selectedZone.add(element);
            zoneString.value =
                "$zoneString${zoneString.isEmpty ? "" : ","} ${Constant.localizationName(list.first.name)}";
          }
        }
        zoneNameController.value.text = zoneString.value;
      }

      // Restore Vehicle Selection using vehicleTypeId (most specific) or fallback to serviceId
      if (driverModel.value.vehicleInformation != null ||
          driverModel.value.serviceId != null) {
        String? vTypeId = driverModel.value.vehicleInformation?.vehicleTypeId;
        String? sId = driverModel.value.serviceId;

        for (var uv in unifiedVehicleList) {
          // Rule: If it's a freight vehicle, vehicleTypeId matches freightServiceId
          if (vTypeId != null && uv.freightServiceId == vTypeId) {
            selectedUnifiedVehicle.value = uv;
            selectedServiceId.value = vTypeId;
            break;
          }
          // Rule: If it's a passenger service, serviceId matches passengerServiceId
          if (sId != null && uv.passengerServiceId == sId) {
            selectedUnifiedVehicle.value = uv;
            selectedServiceId.value = sId;
            break;
          }
        }
      }
    });

    // Fetch Vehicle Types (for subtypes if used)
    await FireStoreUtils.getVehicleType().then((value) {
      vehicleList = value!;
      if (driverModel.value.vehicleInformation != null) {
        for (var element in vehicleList) {
          if (element.id ==
              driverModel.value.vehicleInformation!.vehicleTypeId) {
            selectedVehicle.value = element;
          }
        }
      }
    });

    // Fetch Rules - Initially clear or fetch default if needed,
    // but now rules depend on selection.
    // We can keep the global list if needed, or just rely on selection.
    // For now, let's just clear it or leave it empty until selection.
    driverRulesList.clear();

    // If we have a selected vehicle (restored from profile), fetch its rules
    if (selectedUnifiedVehicle.value != null) {
      selectVehicle(selectedUnifiedVehicle.value!);
    } else {
      // Optionally fetch global rules if no vehicle selected, or just wait
      // But per requirement, we want rules FROM the vehicle document.
    }

    isLoading.value = false;
    update();
  }

  StreamSubscription<List<DriverRulesModel>>? _rulesSubscription;

  void selectVehicle(UnifiedVehicleModel vehicle) {
    selectedUnifiedVehicle.value = vehicle;
    if (vehicle.passengerServiceId != null) {
      selectedServiceId.value = vehicle.passengerServiceId;
      _listenToDriverRules(CollectionName.service, vehicle.passengerServiceId!);
    } else if (vehicle.freightServiceId != null) {
      selectedServiceId.value = vehicle.freightServiceId;
      _listenToDriverRules(
          CollectionName.freightVehicle, vehicle.freightServiceId!);
    }
  }

  void _listenToDriverRules(String collection, String docId) {
    _rulesSubscription?.cancel();
    _rulesSubscription =
        FireStoreUtils.getVehicleDriverRulesStream(collection, docId)
            .listen((rules) {
      driverRulesList.value = rules;

      // Restore selected rules from profile if available
      if (driverModel.value.vehicleInformation != null &&
          driverModel.value.vehicleInformation!.driverRules != null) {
        selectedDriverRulesList.clear(); // Clear previous selection
        for (var rule in rules) {
          // Check if this rule exists in the user's saved rules
          bool isSelected = driverModel.value.vehicleInformation!.driverRules!
              .any((savedRule) => savedRule.id == rule.id);
          if (isSelected) {
            selectedDriverRulesList.add(rule);
          }
        }
      }
    });
  }

  @override
  void onClose() {
    _rulesSubscription?.cancel();
    super.onClose();
  }
}
