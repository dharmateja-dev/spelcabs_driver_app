import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/contact_us_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<ContactUsController>(
        init: ContactUsController(),
        builder: (controller) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            backgroundColor: AppColors.primary,
            body: Column(
              children: [
                SizedBox(
                  height: Responsive.width(8, context),
                  width: Responsive.width(100, context),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: controller.isLoading.value
                          ? Constant.loader(context)
                          : Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: DefaultTabController(
                                length: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Contact us".tr,
                                          style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600)),
                                      Text(
                                          "Let us know your issue & feedback"
                                              .tr,
                                          style: GoogleFonts.poppins()),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      TabBar(
                                        indicatorWeight: 3,
                                        indicatorColor: isDark
                                            ? Colors.white
                                            : Colors
                                                .black, // OPTIONAL (change if needed)

                                        labelColor: isDark
                                            ? Colors.white
                                            : Colors.black, // Selected Tab
                                        unselectedLabelColor: isDark
                                            ? Colors.grey[400]!
                                            : Colors.grey, // Unselected Tab
                                        tabs: [
                                          Tab(
                                            child: Text(
                                              "Call Us".tr,
                                              style: GoogleFonts.poppins(
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                          Tab(
                                            child: Text(
                                              "Email Us".tr,
                                              style: GoogleFonts.poppins(
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: TabBarView(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 20),
                                              child: Column(
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      Constant.makePhoneCall(
                                                          controller
                                                              .phone.value);
                                                    },
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.call),
                                                        const SizedBox(
                                                          width: 20,
                                                        ),
                                                        Text(controller
                                                            .phone.value)
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  const Divider(),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                          Icons.location_on),
                                                      const SizedBox(
                                                        width: 20,
                                                      ),
                                                      Expanded(
                                                          child: Text(controller
                                                              .address.value))
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text("Write us".tr,
                                                        style:
                                                            GoogleFonts.poppins(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                    Text(
                                                        "Describe your issue"
                                                            .tr,
                                                        style: GoogleFonts
                                                            .poppins()),
                                                    const SizedBox(
                                                      height: 20,
                                                    ),
                                                    TextFieldThem
                                                        .buildValidatedTextField(
                                                            context,
                                                            hintText:
                                                                'Email'.tr,
                                                            controller: controller
                                                                .emailController
                                                                .value,
                                                            errorText:
                                                                controller
                                                                    .emailError
                                                                    .value),
                                                    const SizedBox(
                                                      height: 20,
                                                    ),
                                                    TextFieldThem.buildTextFiled(
                                                        context,
                                                        hintText:
                                                            'Describe your issue and feedback'
                                                                .tr,
                                                        controller: controller
                                                            .feedbackController
                                                            .value,
                                                        maxLine: 5),
                                                    const SizedBox(
                                                      height: 20,
                                                    ),
                                                    ButtonThem.buildButton(
                                                      context,
                                                      title: "Submit".tr,
                                                      onPress: () async {
                                                        if (!controller
                                                            .validateEmail()) {
                                                          return;
                                                        }

                                                        if (controller
                                                            .emailController
                                                            .value
                                                            .text
                                                            .isEmpty) {
                                                          ShowToastDialog.showToast(
                                                              "Please enter email"
                                                                  .tr);
                                                        } else if (controller
                                                            .feedbackController
                                                            .value
                                                            .text
                                                            .isEmpty) {
                                                          ShowToastDialog.showToast(
                                                              "Please enter feedback"
                                                                  .tr);
                                                        } else {
                                                          // Show loading indicator
                                                          ShowToastDialog
                                                              .showLoader(
                                                                  "Submitting your request..."
                                                                      .tr);

                                                          // Submit support request to Firestore
                                                          bool success =
                                                              await FireStoreUtils
                                                                  .submitSupportRequest(
                                                            userEmail: controller
                                                                .emailController
                                                                .value
                                                                .text,
                                                            message: controller
                                                                .feedbackController
                                                                .value
                                                                .text,
                                                            subject: controller
                                                                .subject.value,
                                                            supportEmail:
                                                                controller.email
                                                                    .value,
                                                          );

                                                          ShowToastDialog
                                                              .closeLoader();

                                                          if (success) {
                                                            ShowToastDialog
                                                                .showToast(
                                                                    "Your support request has been submitted successfully!"
                                                                        .tr);
                                                            controller
                                                                .emailController
                                                                .value
                                                                .clear();
                                                            controller
                                                                .feedbackController
                                                                .value
                                                                .clear();
                                                          } else {
                                                            ShowToastDialog
                                                                .showToast(
                                                                    "Failed to submit your request. Please try again."
                                                                        .tr);
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
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
