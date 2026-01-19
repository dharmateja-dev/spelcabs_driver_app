import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/signup_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/ui/auth_screen/login_screen.dart';
import 'package:driver/ui/auth_screen/otp_screen.dart';
import 'package:driver/ui/dashboard_screen.dart';
import 'package:driver/ui/terms_and_condition/terms_and_condition_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({Key? key}) : super(key: key);

  // Helper method to build consistent text fields
  Widget _buildConsistentTextField(
    BuildContext context,
    String hintText,
    TextEditingController controller,
    DarkThemeProvider themeChange, {
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    Widget? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      validator: validator ??
          (value) => value != null && value.isNotEmpty ? null : 'Required',
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      controller: controller,
      textAlign: TextAlign.start,
      style: GoogleFonts.poppins(
          color: themeChange.getThem() ? Colors.white : Colors.black),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: themeChange.getThem()
            ? AppColors.darkTextField
            : AppColors.textField,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        prefixIcon: prefixIcon,
        disabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(
            color: themeChange.getThem()
                ? AppColors.darkTextFieldBorder
                : AppColors.textFieldBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(
            color: themeChange.getThem()
                ? AppColors.darkTextFieldBorder
                : AppColors.textFieldBorder,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(
            color: themeChange.getThem()
                ? AppColors.darkTextFieldBorder
                : AppColors.textFieldBorder,
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(
            color: themeChange.getThem()
                ? AppColors.darkTextFieldBorder
                : AppColors.textFieldBorder,
            width: 1,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(
            color: themeChange.getThem()
                ? AppColors.darkTextFieldBorder
                : AppColors.textFieldBorder,
            width: 1,
          ),
        ),
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(
          color: themeChange.getThem() ? Colors.white54 : Colors.black54,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<SignupController>(
        init: SignupController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            body: SingleChildScrollView(
              child: Form(
                key: controller.formKey.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset("assets/images/login_image.png",
                        width: Responsive.width(100, context)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text("Sign Up".tr,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600, fontSize: 18)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text("Create your account to get started".tr,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w400)),
                          ),
                          const SizedBox(height: 20),

                          // Full Name Field
                          _buildConsistentTextField(
                            context,
                            'Full Name'.tr,
                            controller.fullNameController.value,
                            themeChange,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Full name is required';
                              }
                              // Remove leading/trailing spaces for validation
                              String trimmedValue = value.trim();
                              if (trimmedValue.isEmpty) {
                                return 'Full name cannot be only spaces';
                              }
                              // Only allow letters, spaces, hyphens, apostrophes, and dots
                              RegExp nameRegex = RegExp(r"^[a-zA-Z\s\-'.]+$");
                              if (!nameRegex.hasMatch(trimmedValue)) {
                                return 'Name can only contain letters, spaces, hyphens, and apostrophes';
                              }
                              // Check minimum length (at least 2 characters)
                              if (trimmedValue.length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Email Field with validation
                          TextFieldThem.buildValidatedTextField(
                            context,
                            hintText: 'Email'.tr,
                            controller: controller.emailController.value,
                            errorText: controller.emailError.value,
                            keyBoardType: TextInputType.emailAddress,
                            textCapitalization: TextCapitalization.none,
                          ),
                          const SizedBox(height: 10),

                          // Phone Number Field with validation
                          TextFieldThem.buildValidatedPhoneField(
                            context,
                            controller: controller.phoneNumberController.value,
                            errorText: controller.phoneError.value,
                            hintText: "Phone number".tr,
                            maxLength: 10,
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
                          const SizedBox(height: 30),

                          ButtonThem.buildButton(
                            context,
                            title: "Sign Up".tr,
                            onPress: () async {
                              await controller.validateAndSignup();
                            },
                          ),
                          const SizedBox(height: 20),

                          // Navigation to Login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ".tr,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: themeChange.getThem()
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Get.to(const LoginScreen());
                                },
                                child: Text(
                                  "Login".tr,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 40),
                            child: Row(
                              children: [
                                const Expanded(child: Divider(height: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Text("OR".tr,
                                      style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                ),
                                const Expanded(child: Divider(height: 1)),
                              ],
                            ),
                          ),

                          ButtonThem.buildBorderButton(
                            context,
                            title: "Sign up with google".tr,
                            iconVisibility: true,
                            iconAssetImage: 'assets/icons/ic_google.png',
                            onPress: () async {
                              await controller.signInWithGoogle();
                              // ShowToastDialog.showLoader("Please wait".tr);
                              // await controller.signInWithGoogle().then((value) {
                              //   ShowToastDialog.closeLoader();
                              //   if (value != null) {
                              //     FireStoreUtils.userExitOrNot(value.user!.uid).then((userExit) {
                              //       if (userExit == true) {
                              //         ShowToastDialog.showToast("Account already exists. Please login instead.".tr);
                              //       } else {
                              //         DriverUserModel userModel = DriverUserModel();
                              //         userModel.id = value.user!.uid;
                              //         userModel.email = value.user!.email;
                              //         userModel.fullName = value.user!.displayName;
                              //         userModel.profilePic = value.user!.photoURL;
                              //         userModel.loginType = Constant.googleLoginType;
                              //         userModel.documentVerification = false;
                              //         userModel.isOnline = false;
                              //         userModel.createdAt = Timestamp.now();
                              //
                              //         FireStoreUtils.updateDriverUser(userModel).then((result) {
                              //           if (result) {
                              //             Get.to(const DashBoardScreen());
                              //           }
                              //         });
                              //       }
                              //     });
                              //   }
                              // });
                            },
                          ),
                          const SizedBox(height: 16),

                          Visibility(
                            visible: Platform.isIOS,
                            child: ButtonThem.buildBorderButton(
                              context,
                              title: "Sign up with apple".tr,
                              iconVisibility: true,
                              iconAssetImage: 'assets/icons/ic_apple.png',
                              onPress: () async {
                                await controller.signInWithApple();
                                // ShowToastDialog.showLoader("Please wait".tr);
                                // await controller.signInWithApple().then((value) {
                                //   ShowToastDialog.closeLoader();
                                //   if (value != null) {
                                //     Map<String, dynamic> map = value;
                                //     AuthorizationCredentialAppleID appleCredential = map['appleCredential'];
                                //     UserCredential userCredential = map['userCredential'];
                                //
                                //     FireStoreUtils.userExitOrNot(userCredential.user!.uid).then((userExit) {
                                //       if (userExit == true) {
                                //         ShowToastDialog.showToast("Account already exists. Please login instead.".tr);
                                //       } else {
                                //         DriverUserModel userModel = DriverUserModel();
                                //         userModel.id = userCredential.user!.uid;
                                //         userModel.profilePic = userCredential.user!.photoURL;
                                //         userModel.loginType = Constant.appleLoginType;
                                //         userModel.email = userCredential.additionalUserInfo!.profile!['email'];
                                //         userModel.fullName = "${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}";
                                //         userModel.documentVerification = false;
                                //         userModel.isOnline = false;
                                //         userModel.createdAt = Timestamp.now();
                                //
                                //         FireStoreUtils.updateDriverUser(userModel).then((result) {
                                //           if (result) {
                                //             Get.to(const DashBoardScreen());
                                //           }
                                //         });
                                //       }
                                //     });
                                //   }
                                // });
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  text: 'By tapping "Sign Up" you agree to '.tr,
                  style: GoogleFonts.poppins(),
                  children: <TextSpan>[
                    TextSpan(
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Get.to(const TermsAndConditionScreen(type: "terms"));
                        },
                      text: 'Terms and Conditions'.tr,
                      style: GoogleFonts.poppins(
                          decoration: TextDecoration.underline),
                    ),
                    TextSpan(text: ' and ', style: GoogleFonts.poppins()),
                    TextSpan(
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Get.to(
                              const TermsAndConditionScreen(type: "privacy"));
                        },
                      text: 'Privacy Policy'.tr,
                      style: GoogleFonts.poppins(
                          decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
