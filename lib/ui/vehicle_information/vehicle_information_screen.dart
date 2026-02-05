import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/vehicle_information_controller.dart';
import 'package:driver/controller/home_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/driver_rules_model.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/vehicle_type_model.dart';
import 'package:driver/model/unified_vehicle_model.dart';
import 'package:driver/model/zone_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/app_logger.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VehicleInformationScreen extends StatelessWidget {
  const VehicleInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<VehicleInformationController>(
      init: VehicleInformationController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.primary,
          body: Column(
            children: [
              SizedBox(
                height: Responsive.width(10, context),
                width: Responsive.width(100, context),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25))),
                  child: controller.isLoading.value
                      ? Constant.loader(context)
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  height: 10,
                                ),
                                SizedBox(
                                  height: Responsive.height(18, context),
                                  child: ListView.builder(
                                    itemCount:
                                        controller.unifiedVehicleList.length,
                                    scrollDirection: Axis.horizontal,
                                    shrinkWrap: true,
                                    itemBuilder: (context, index) {
                                      UnifiedVehicleModel vehicle =
                                          controller.unifiedVehicleList[index];
                                      return Obx(
                                        () => InkWell(
                                          onTap: () async {
                                            if (!controller
                                                .isVehicleInfoSubmitted) {
                                              controller.selectVehicle(vehicle);
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(6.0),
                                            child: Container(
                                              width:
                                                  Responsive.width(28, context),
                                              decoration: BoxDecoration(
                                                  color: controller
                                                              .selectedUnifiedVehicle
                                                              .value ==
                                                          vehicle
                                                      ? AppColors.primary
                                                      : themeChange.getThem()
                                                          ? AppColors
                                                              .darkService
                                                          : controller.colors[
                                                              index %
                                                                  controller
                                                                      .colors
                                                                      .length],
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(20),
                                                  )),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                            color: AppColors
                                                                .background,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(
                                                              Radius.circular(
                                                                  20),
                                                            )),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: CachedNetworkImage(
                                                        imageUrl: vehicle.image
                                                            .toString(),
                                                        fit: BoxFit.contain,
                                                        height:
                                                            Responsive.height(
                                                                8, context),
                                                        width: Responsive.width(
                                                            18, context),
                                                        placeholder:
                                                            (context, url) =>
                                                                Constant.loader(
                                                                    context),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            Image.network(
                                                                'https://firebasestorage.googleapis.com/v0/b/goride-1a752.appspot.com/o/placeholderImages%2Fuser-placeholder.jpeg?alt=media&token=34a73d67-ba1d-4fe4-a29f-271d3e3ca115'),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Text(vehicle.name,
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          GoogleFonts.poppins(
                                                              color: controller
                                                                          .selectedUnifiedVehicle
                                                                          .value ==
                                                                      vehicle
                                                                  ? Colors.white
                                                                  : themeChange
                                                                          .getThem()
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                TextFieldThem.buildValidatedTextField(
                                  context,
                                  hintText: 'Vehicle Number'.tr,
                                  controller:
                                      controller.vehicleNumberController.value,
                                  errorText:
                                      controller.vehicleNumberError.value,
                                  enable: !controller.isVehicleInfoSubmitted,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  keyBoardType: TextInputType
                                      .text, // Vehicle numbers are alphanumeric
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                InkWell(
                                  onTap: !controller.isVehicleInfoSubmitted
                                      ? () async {
                                          await Constant.selectDate(context)
                                              .then((value) {
                                            if (value != null) {
                                              controller.selectedDate.value =
                                                  value;
                                              controller
                                                  .registrationDateController
                                                  .value
                                                  .text = DateFormat(
                                                      "dd-MM-yyyy")
                                                  .format(value);
                                            }
                                          });
                                        }
                                      : null,
                                  child: TextField(
                                    controller: controller
                                        .registrationDateController.value,
                                    enabled: false,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: themeChange.getThem()
                                          ? AppColors.darkTextField
                                          : AppColors.textField,
                                      contentPadding: const EdgeInsets.only(
                                          left: 10, right: 10),
                                      hintText: 'Registration Date'.tr,
                                      hintStyle: TextStyle(
                                          color: themeChange.getThem()
                                              ? Colors.white
                                              : Colors.black),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                    ),
                                    style: TextStyle(
                                        color: themeChange.getThem()
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Obx(() {
                                  // Determine if selected service is a car-like service (Car/Cab/Taxi)
                                  bool isCarService = false;
                                  if (controller.serviceList.isNotEmpty &&
                                      controller.selectedServiceId.value !=
                                          null &&
                                      controller.selectedServiceId.value!
                                          .isNotEmpty) {
                                    try {
                                      final sel = controller.serviceList
                                          .firstWhere(
                                              (s) =>
                                                  s.id ==
                                                  controller
                                                      .selectedServiceId.value,
                                              orElse: () => ServiceModel());
                                      final title = sel.title != null &&
                                              sel.title!.isNotEmpty
                                          ? Constant.localizationTitle(
                                                  sel.title)
                                              .toLowerCase()
                                          : "";
                                      if (title.contains('car') ||
                                          title.contains('taxi') ||
                                          title.contains('cab')) {
                                        isCarService = true;
                                      }
                                    } catch (e) {
                                      isCarService = false;
                                    }
                                  }

                                  if (!isCarService) {
                                    // Hide vehicle type for non-car services
                                    return const SizedBox.shrink();
                                  }

                                  return DropdownButtonFormField<
                                          VehicleTypeModel>(
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: themeChange.getThem()
                                            ? AppColors.darkTextField
                                            : AppColors.textField,
                                        contentPadding: const EdgeInsets.only(
                                            left: 10, right: 10),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(4)),
                                          borderSide: BorderSide(
                                              color: themeChange.getThem()
                                                  ? AppColors
                                                      .darkTextFieldBorder
                                                  : AppColors.textFieldBorder,
                                              width: 1),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(4)),
                                          borderSide: BorderSide(
                                              color: themeChange.getThem()
                                                  ? AppColors
                                                      .darkTextFieldBorder
                                                  : AppColors.textFieldBorder,
                                              width: 1),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(4)),
                                          borderSide: BorderSide(
                                              color: themeChange.getThem()
                                                  ? AppColors
                                                      .darkTextFieldBorder
                                                  : AppColors.textFieldBorder,
                                              width: 1),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(4)),
                                          borderSide: BorderSide(
                                              color: themeChange.getThem()
                                                  ? AppColors
                                                      .darkTextFieldBorder
                                                  : AppColors.textFieldBorder,
                                              width: 1),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(4)),
                                          borderSide: BorderSide(
                                              color: themeChange.getThem()
                                                  ? AppColors
                                                      .darkTextFieldBorder
                                                  : AppColors.textFieldBorder,
                                              width: 1),
                                        ),
                                      ),
                                      validator: (value) => value == null
                                          ? 'field required'
                                          : null,
                                      initialValue: controller
                                                  .selectedVehicle.value.id ==
                                              null
                                          ? null
                                          : controller.selectedVehicle.value,
                                      onChanged: !controller
                                              .isVehicleInfoSubmitted
                                          ? (value) {
                                              controller.selectedVehicle.value =
                                                  value!;
                                            }
                                          : null,
                                      hint: Text("Select vehicle type".tr),
                                      items: (() {
                                        // Filter vehicle types to show only car subtypes when service is car-like
                                        List<VehicleTypeModel> displayList =
                                            controller.vehicleList;
                                        final keywords = [
                                          'mini',
                                          'sedan',
                                          'suv',
                                          'hatchback',
                                          'van',
                                          'compact',
                                          'micro',
                                          'xl'
                                        ];

                                        final filtered = controller.vehicleList
                                            .where((item) {
                                          final name =
                                              Constant.localizationName(
                                                      item.name)
                                                  .toLowerCase();
                                          return keywords
                                              .any((k) => name.contains(k));
                                        }).toList();

                                        if (filtered.isNotEmpty) {
                                          displayList = filtered;
                                        }

                                        return displayList.map((item) {
                                          return DropdownMenuItem(
                                            value: item,
                                            child: Text(
                                                Constant.localizationName(
                                                    item.name)),
                                          );
                                        }).toList();
                                      })());
                                }),
                                const SizedBox(
                                  height: 10,
                                ),
                                DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: themeChange.getThem()
                                          ? AppColors.darkTextField
                                          : AppColors.textField,
                                      contentPadding: const EdgeInsets.only(
                                          left: 10, right: 10),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                    ),
                                    validator: (value) =>
                                        value == null ? 'field required' : null,
                                    initialValue:
                                        controller.selectedColor.value.isEmpty
                                            ? null
                                            : controller.selectedColor.value,
                                    onChanged:
                                        !controller.isVehicleInfoSubmitted
                                            ? (value) {
                                                controller.selectedColor.value =
                                                    value!;
                                              }
                                            : null,
                                    hint: Text("Select vehicle color".tr),
                                    items: controller.carColorList.map((item) {
                                      return DropdownMenuItem(
                                        value: item,
                                        child: Text(item.toString()),
                                      );
                                    }).toList()),
                                const SizedBox(
                                  height: 10,
                                ),
                                DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: themeChange.getThem()
                                          ? AppColors.darkTextField
                                          : AppColors.textField,
                                      contentPadding: const EdgeInsets.only(
                                          left: 10, right: 10),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                    ),
                                    validator: (value) =>
                                        value == null ? 'field required' : null,
                                    initialValue: controller
                                            .seatsController.value.text.isEmpty
                                        ? null
                                        : controller.seatsController.value.text,
                                    onChanged:
                                        !controller.isVehicleInfoSubmitted
                                            ? (value) {
                                                controller.seatsController.value
                                                    .text = value!;
                                              }
                                            : null,
                                    hint: Text("How Many Seats".tr),
                                    items: controller.sheetList.map((item) {
                                      return DropdownMenuItem(
                                        value: item,
                                        child: Text(item.toString()),
                                      );
                                    }).toList()),
                                const SizedBox(
                                  height: 10,
                                ),
                                InkWell(
                                  onTap: !controller.isVehicleInfoSubmitted
                                      ? () {
                                          zoneDialog(context, controller);
                                        }
                                      : null,
                                  child: TextField(
                                    controller:
                                        controller.zoneNameController.value,
                                    enabled: false,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: themeChange.getThem()
                                          ? AppColors.darkTextField
                                          : AppColors.textField,
                                      contentPadding: const EdgeInsets.only(
                                          left: 10, right: 10),
                                      hintText: 'Select Zone'.tr,
                                      hintStyle: TextStyle(
                                          color: themeChange.getThem()
                                              ? Colors.white
                                              : Colors.black),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                    ),
                                    style: TextStyle(
                                        color: themeChange.getThem()
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text("Select Your Rules".tr,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16)),
                                StreamBuilder<List<DriverRulesModel>>(
                                  stream: FireStoreUtils.getDriverRulesStream(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    if (snapshot.hasError) {
                                      return Text(
                                          "Error: ${snapshot.error}".tr);
                                    }
                                    if (!snapshot.hasData ||
                                        snapshot.data!.isEmpty) {
                                      return const SizedBox();
                                    }

                                    // Update the full list in controller (optional but good for consistency)
                                    controller.driverRulesList.value =
                                        snapshot.data!;

                                    return Obx(
                                      () => ListBody(
                                        children: snapshot.data!
                                            .map((item) => CheckboxListTile(
                                                  activeColor:
                                                      themeChange.getThem()
                                                          ? AppColors
                                                              .darkModePrimary
                                                          : AppColors.primary,
                                                  checkColor:
                                                      themeChange.getThem()
                                                          ? Colors.black
                                                          : Colors.white,
                                                  value: controller
                                                      .selectedDriverRulesList
                                                      .any((element) =>
                                                          element.id ==
                                                          item.id),
                                                  title: Text(
                                                      Constant.localizationName(
                                                          item.name),
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400)),
                                                  onChanged: !controller
                                                          .isVehicleInfoSubmitted
                                                      ? (value) {
                                                          if (value == true) {
                                                            // Only add if not already present
                                                            if (!controller
                                                                .selectedDriverRulesList
                                                                .any((rule) =>
                                                                    rule.id ==
                                                                    item.id)) {
                                                              controller
                                                                  .selectedDriverRulesList
                                                                  .add(item);
                                                            }
                                                          } else {
                                                            // Remove by filtering out the item
                                                            controller
                                                                .selectedDriverRulesList
                                                                .removeWhere(
                                                                    (element) =>
                                                                        element
                                                                            .id ==
                                                                        item.id);
                                                          }
                                                        }
                                                      : null,
                                                ))
                                            .toList(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                if (!controller.isVehicleInfoSubmitted)
                                  Align(
                                    alignment: Alignment.center,
                                    child: ButtonThem.buildButton(
                                      context,
                                      title: "Save".tr,
                                      onPress: () async {
                                        ShowToastDialog.showLoader(
                                            "Please wait".tr);

                                        if (controller
                                                .selectedUnifiedVehicle.value ==
                                            null) {
                                          ShowToastDialog.closeLoader();
                                          ShowToastDialog.showToast(
                                              "Please select service".tr);
                                          return;
                                        }

                                        // Validate vehicle number with duplicate check (async)
                                        final isVehicleValid = await controller
                                            .validateVehicleNumberWithDuplicateCheck();
                                        if (!isVehicleValid) {
                                          ShowToastDialog.closeLoader();
                                          // Validation failed, error shows inline
                                          return;
                                        }

                                        // Normalize vehicle number to uppercase
                                        controller.normalizeVehicleNumber();

                                        if (controller
                                            .registrationDateController
                                            .value
                                            .text
                                            .isEmpty) {
                                          ShowToastDialog.closeLoader();
                                          ShowToastDialog.showToast(
                                              "Please select registration date"
                                                  .tr);
                                          return;
                                        }

                                        // Only require vehicle type when selected service appears to be car-like
                                        // We use the unified vehicle name or underlying service titles
                                        UnifiedVehicleModel selected =
                                            controller
                                                .selectedUnifiedVehicle.value!;
                                        bool isCarLike = false;
                                        String name =
                                            selected.name.toLowerCase();
                                        if (name.contains('car') ||
                                            name.contains('taxi') ||
                                            name.contains('cab')) {
                                          isCarLike = true;
                                        }

                                        if (isCarLike &&
                                            (controller.selectedVehicle.value
                                                        .id ==
                                                    null ||
                                                controller.selectedVehicle.value
                                                    .id!.isEmpty)) {
                                          ShowToastDialog.closeLoader();
                                          ShowToastDialog.showToast(
                                              "Please enter Vehicle type".tr);
                                          return;
                                        }

                                        if (controller
                                            .selectedColor.value.isEmpty) {
                                          ShowToastDialog.closeLoader();
                                          ShowToastDialog.showToast(
                                              "Please enter Vehicle color".tr);
                                          return;
                                        }

                                        if (controller.seatsController.value
                                            .text.isEmpty) {
                                          ShowToastDialog.closeLoader();
                                          ShowToastDialog.showToast(
                                              "Please enter seats".tr);
                                          return;
                                        }

                                        if (controller.selectedZone.isEmpty) {
                                          ShowToastDialog.closeLoader();
                                          ShowToastDialog.showToast(
                                              "Please select Zone".tr);
                                          return;
                                        }

                                        // All validations passed, proceed to save

                                        // Update Active Services Map
                                        Map<String, bool> activeServices = {};
                                        if (selected.passengerServiceId !=
                                            null) {
                                          activeServices[selected
                                              .passengerServiceId!] = true;
                                        }
                                        if (selected.freightServiceId != null) {
                                          activeServices[selected
                                              .freightServiceId!] = true;
                                        }
                                        controller.driverModel.value
                                            .activeServices = activeServices;

                                        // Fallback/Legacy serviceID (use passenger if available, else freight)
                                        if (selected.passengerServiceId !=
                                            null) {
                                          controller
                                                  .driverModel.value.serviceId =
                                              selected.passengerServiceId;
                                        } else if (selected.freightServiceId !=
                                            null) {
                                          controller
                                                  .driverModel.value.serviceId =
                                              selected.freightServiceId;
                                        }

                                        controller.driverModel.value.zoneIds =
                                            controller.selectedZone;

                                        controller.driverModel.value.vehicleInformation = VehicleInformation(
                                            registrationDate: Timestamp.fromDate(
                                                controller.selectedDate.value!),
                                            vehicleColor:
                                                controller.selectedColor.value,
                                            vehicleNumber: controller
                                                .vehicleNumberController
                                                .value
                                                .text,
                                            vehicleType: isCarLike
                                                ? controller
                                                    .selectedVehicle.value.name
                                                : null,
                                            vehicleTypeId: isCarLike
                                                ? controller
                                                    .selectedVehicle.value.id
                                                : null,
                                            seats: controller
                                                .seatsController.value.text,
                                            driverRules:
                                                List<DriverRulesModel>.from(controller.selectedDriverRulesList.toList()));

                                        await FireStoreUtils.updateDriverUser(
                                                controller.driverModel.value)
                                            .then((value) async {
                                          ShowToastDialog.closeLoader();
                                          if (value == true) {
                                            ShowToastDialog.showToast(
                                                "Information update successfully"
                                                    .tr);

                                            // Refresh HomeController data to ensure orders and location get refreshed
                                            try {
                                              if (Get.isRegistered<
                                                  HomeController>()) {
                                                final homeController =
                                                    Get.find<HomeController>();
                                                homeController.isLoading.value =
                                                    true;
                                                // Re-fetch driver document and active rides; also restart location updates
                                                homeController.getDriver();
                                                await Future.delayed(
                                                    const Duration(
                                                        milliseconds: 500));
                                                homeController.getActiveRide();
                                                homeController
                                                    .updateCurrentLocation();
                                                homeController.isLoading.value =
                                                    false;
                                              }
                                            } catch (e) {
                                              // Non-fatal: just log
                                              AppLogger.error(
                                                  "Error refreshing HomeController after saving vehicle info: $e",
                                                  tag:
                                                      "VehicleInformationScreen");
                                            }
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Text(
                                    "You can not change once you select one service type if you want to change please contact to administrator "
                                        .tr,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins()),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void zoneDialog(BuildContext context, VehicleInformationController controller) {
    Widget cancelButton = TextButton(
      child: Text(
        "Cancel".tr,
        style: const TextStyle(color: Colors.white70),
      ),
      onPressed: () {
        Get.back();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Continue".tr),
      onPressed: () {
        if (controller.selectedZone.isEmpty) {
          ShowToastDialog.showToast("Please select zone".tr);
        } else {
          String nameValue = "";
          for (var element in controller.selectedZone) {
            List<ZoneModel> list =
                controller.zoneList.where((p0) => p0.id == element).toList();
            if (list.isNotEmpty) {
              nameValue =
                  "$nameValue${nameValue.isEmpty ? "" : ","} ${Constant.localizationName(list.first.name)}";
            }
          }
          controller.zoneNameController.value.text = nameValue;
          Get.back();
        }
      },
    );
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Zone list'.tr),
            content: SizedBox(
              width: Responsive.width(
                  90, context), // Change as per your requirement
              child: controller.zoneList.isEmpty
                  ? Container()
                  : Obx(
                      () => ListView.builder(
                        shrinkWrap: true,
                        itemCount: controller.zoneList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Obx(
                            () => CheckboxListTile(
                              value: controller.selectedZone
                                  .contains(controller.zoneList[index].id),
                              onChanged: !controller.isVehicleInfoSubmitted
                                  ? (value) {
                                      if (controller.selectedZone.contains(
                                          controller.zoneList[index].id)) {
                                        controller.selectedZone.remove(
                                            controller.zoneList[index]
                                                .id); // unselect
                                      } else {
                                        controller.selectedZone.add(controller
                                            .zoneList[index].id); // select
                                      }
                                    }
                                  : null,
                              activeColor: AppColors.primary,
                              title: Text(Constant.localizationName(
                                  controller.zoneList[index].name)),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            actions: [
              cancelButton,
              continueButton,
            ],
          );
        });
  }
}
