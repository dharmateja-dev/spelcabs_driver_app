import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/login_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/ui/auth_screen/signup_screen.dart';
import 'package:driver/ui/terms_and_condition/terms_and_condition_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<LoginController>(
        init: LoginController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
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
                            child: Text("Login".tr,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600, fontSize: 18)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                                "Welcome Back! We are happy to have \n you back"
                                    .tr,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w400)),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
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
                          const SizedBox(
                            height: 30,
                          ),
                          ButtonThem.buildButton(
                            context,
                            title: "Next".tr,
                            onPress: () {
                              controller.sendCode();
                            },
                          ),
                          const SizedBox(height: 20),
                          // Navigation to Sign Up
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ".tr,
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
                                  Get.to(const SignupScreen());
                                },
                                child: Text(
                                  "Sign Up".tr,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: themeChange.getThem()
                                        ? Colors.white
                                        : AppColors.primary,
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
                                const Expanded(
                                    child: Divider(
                                  height: 1,
                                )),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Text(
                                    "OR".tr,
                                    style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const Expanded(
                                    child: Divider(
                                  height: 1,
                                )),
                              ],
                            ),
                          ),
                          ButtonThem.buildBorderButton(
                            context,
                            title: "Login with google".tr,
                            iconVisibility: true,
                            iconAssetImage: 'assets/icons/ic_google.png',
                            onPress: () async {
                              await controller.signInWithGoogle();
                              // ShowToastDialog.showLoader("Please wait".tr);
                              // await controller.signInWithGoogle().then((value) {
                              //   ShowToastDialog.closeLoader();
                              //   if (value != null) {
                              //     if (value.additionalUserInfo!.isNewUser) {
                              //       log("----->new user");
                              //       DriverUserModel userModel = DriverUserModel();
                              //       userModel.id = value.user!.uid;
                              //       userModel.email = value.user!.email;
                              //       userModel.fullName = value.user!.displayName;
                              //       userModel.profilePic = value.user!.photoURL;
                              //       userModel.loginType = Constant.googleLoginType;
                              //
                              //       ShowToastDialog.closeLoader();
                              //       Get.to(const InformationScreen(), arguments: {
                              //         "userModel": userModel,
                              //       });
                              //     } else {
                              //       log("----->old user");
                              //       FireStoreUtils.userExitOrNot(value.user!.uid).then((userExit) {
                              //         if (userExit == true) {
                              //           ShowToastDialog.closeLoader();
                              //           Get.to(const DashBoardScreen());
                              //         } else {
                              //           DriverUserModel userModel = DriverUserModel();
                              //           userModel.id = value.user!.uid;
                              //           userModel.email = value.user!.email;
                              //           userModel.fullName = value.user!.displayName;
                              //           userModel.profilePic = value.user!.photoURL;
                              //           userModel.loginType = Constant.googleLoginType;
                              //
                              //           Get.to(const InformationScreen(), arguments: {
                              //             "userModel": userModel,
                              //           });
                              //         }
                              //       });
                              //     }
                              //   }
                              // });
                            },
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Visibility(
                              visible: Platform.isIOS,
                              child: ButtonThem.buildBorderButton(
                                context,
                                title: "Login with apple".tr,
                                iconVisibility: true,
                                iconAssetImage: 'assets/icons/ic_apple.png',
                                onPress: () async {
                                  ShowToastDialog.showLoader("Please wait".tr);
                                  await controller.signInWithApple();
                                  // await controller.signInWithApple().then((value) {
                                  //   ShowToastDialog.closeLoader();
                                  //   if (value != null) {
                                  //     Map<String, dynamic> map = value;
                                  //     AuthorizationCredentialAppleID appleCredential = map['appleCredential'];
                                  //     UserCredential userCredential = map['userCredential'];
                                  //
                                  //     if (userCredential.additionalUserInfo!.isNewUser) {
                                  //       log("----->new user");
                                  //       DriverUserModel userModel = DriverUserModel();
                                  //       userModel.id = userCredential.user!.uid;
                                  //       userModel.profilePic = userCredential.user!.photoURL;
                                  //       userModel.loginType = Constant.appleLoginType;
                                  //       userModel.email = userCredential.additionalUserInfo!.profile!['email'];
                                  //       userModel.fullName = "${appleCredential.givenName} ${appleCredential.familyName}";
                                  //
                                  //       ShowToastDialog.closeLoader();
                                  //       Get.to(const InformationScreen(), arguments: {
                                  //         "userModel": userModel,
                                  //       });
                                  //     }
                                  //     else {
                                  //       log("----->old user");
                                  //       FireStoreUtils.userExitOrNot(userCredential.user!.uid).then((userExit) {
                                  //         if (userExit == true) {
                                  //           ShowToastDialog.closeLoader();
                                  //           Get.to(const DashBoardScreen());
                                  //         } else {
                                  //           DriverUserModel userModel = DriverUserModel();
                                  //           userModel.id = userCredential.user!.uid;
                                  //           userModel.profilePic = userCredential.user!.photoURL;
                                  //           userModel.loginType = Constant.appleLoginType;
                                  //           userModel.email = userCredential.additionalUserInfo!.profile!['email'];
                                  //           userModel.fullName = "${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}";
                                  //
                                  //           Get.to(const InformationScreen(), arguments: {
                                  //             "userModel": userModel,
                                  //           });
                                  //         }
                                  //       });
                                  //     }
                                  //   }
                                  //
                                  // });
                                },
                              )),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    text: 'By tapping "Next" you agree to '.tr,
                    style: GoogleFonts.poppins(),
                    children: <TextSpan>[
                      TextSpan(
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Get.to(const TermsAndConditionScreen(
                                type: "terms",
                              ));
                            },
                          text: 'Terms and Conditions'.tr,
                          style: GoogleFonts.poppins(
                              decoration: TextDecoration.underline)),
                      TextSpan(text: ' and ', style: GoogleFonts.poppins()),
                      TextSpan(
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Get.to(const TermsAndConditionScreen(
                                type: "privacy",
                              ));
                            },
                          text: 'Privacy Policy'.tr,
                          style: GoogleFonts.poppins(
                              decoration: TextDecoration.underline)),
                      // can add more TextSpans here...
                    ],
                  ),
                )),
          );
        });
  }
}
