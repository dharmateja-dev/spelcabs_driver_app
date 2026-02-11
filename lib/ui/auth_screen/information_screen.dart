import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/information_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/ui/dashboard_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/preferences.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../themes/responsive.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<InformationController>(
        init: InformationController(),
        builder: (controller) {
          return Scaffold(
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset("assets/images/login_image.png",
                      width: Responsive.width(100, context)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text("Sign up".tr,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 18)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                              "Create your account to start using Spelcabs".tr,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w400)),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextFieldThem.buildTextFiled(context,
                            hintText: 'Full name'.tr,
                            controller: controller.fullNameController.value),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFieldThem.buildValidatedPhoneField(
                          context,
                          controller: controller.phoneNumberController.value,
                          errorText: controller.phoneError.value,
                          hintText: "Phone number".tr,
                          // maxLength: 10, // Removed strict length here as ValidationUtils handles flexible length for social login flow if desirable, or strict 10. Let's stick to 10-digit validation logic in controller, so field could have length limit if desired.
                          // Using standard 10 digit limit for consistency as "valid 10-digit number" was the request.
                          maxLength: 10,
                          enable: controller.loginType.value ==
                                  Constant.phoneLoginType
                              ? false
                              : true,
                          countryCodePicker: CountryCodePicker(
                            onChanged: (value) {
                              controller.countryCode.value =
                                  value.dialCode.toString();
                            },
                            dialogBackgroundColor: themeChange.getThem()
                                ? AppColors.darkBackground
                                : AppColors.background,
                            initialSelection: controller.countryCode.value,
                            comparator: (a, b) =>
                                b.name!.compareTo(a.name.toString()),
                            flagDecoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(2)),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFieldThem.buildValidatedTextField(context,
                            hintText: 'Email'.tr,
                            controller: controller.emailController.value,
                            errorText: controller.emailError.value,
                            enable: controller.loginType.value ==
                                    Constant.googleLoginType
                                ? false
                                : true),
                        const SizedBox(
                          height: 60,
                        ),
                        ButtonThem.buildButton(context,
                            title: "Create account".tr, onPress: () async {
                          // Validate Phone and Email (only if editable)
                          if (!controller.validateAll()) {
                            return;
                          }

                          if (controller
                              .fullNameController.value.text.isEmpty) {
                            ShowToastDialog.showToast(
                                "Please enter full name".tr);
                          } else {
                            ShowToastDialog.showLoader("Please wait".tr);

                            // Update the userModel with the collected data
                            controller.userModel.value.fullName =
                                controller.fullNameController.value.text;
                            controller.userModel.value.email =
                                controller.emailController.value.text;
                            controller.userModel.value.countryCode =
                                controller.countryCode.value;
                            controller.userModel.value.phoneNumber =
                                controller.phoneNumberController.value.text;

                            controller.userModel.value.documentVerification =
                                false;
                            controller.userModel.value.isOnline = false;

                            // ✅ Only set createdAt if it's null (new user)
                            if (controller.userModel.value.createdAt == null) {
                              controller.userModel.value.createdAt =
                                  Timestamp.now();
                            }

                            // Save/update the DriverUserModel in Firestore
                            await FireStoreUtils.updateDriverUser(
                                    controller.userModel.value)
                                .then((value) async {
                              ShowToastDialog.closeLoader();
                              if (value == true) {
                                // Save to preferences after successful Firestore update
                                await Preferences.saveDriverUserData(
                                    controller.userModel.value);
                                await Preferences.setBoolean(
                                    Constant.isLoggedInKey, true);
                                FireStoreUtils.currentDriverUser =
                                    controller.userModel.value;
                                Get.offAll(const DashBoardScreen());
                              } else {
                                ShowToastDialog.showToast(
                                    "Failed to save information. Please try again.");
                              }
                            });
                          }
                        }),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }
}
