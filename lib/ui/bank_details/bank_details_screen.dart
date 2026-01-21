import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/bank_details_controller.dart';
import 'package:driver/model/bank_details_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class BankDetailsScreen extends StatelessWidget {
  const BankDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<BankDetailsController>(
        init: BankDetailsController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: AppColors.primary,
            body: Column(
              children: [
                SizedBox(
                  height: Responsive.width(12, context),
                  width: Responsive.width(100, context),
                ),
                Expanded(
                  child: Container(
                    height: Responsive.height(100, context),
                    width: Responsive.width(100, context),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25))),
                    child: controller.isLoading.value
                        ? Constant.loader(context)
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Bank Name".tr,
                                      style: GoogleFonts.poppins()),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  TextFieldThem.buildTextFiled(context,
                                      hintText: 'Bank Name'.tr,
                                      controller:
                                          controller.bankNameController.value),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text("IFSC Code".tr,
                                      style: GoogleFonts.poppins()),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  TextFieldThem.buildTextFiled(context,
                                      hintText: 'IFSC Code'.tr,
                                      keyBoardType: TextInputType.text,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      controller: controller
                                          .branchNameController.value),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text("Holder Name".tr,
                                      style: GoogleFonts.poppins()),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  TextFieldThem.buildTextFiled(context,
                                      hintText: 'Holder Name'.tr,
                                      controller: controller
                                          .holderNameController.value),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text("Account Number".tr,
                                      style: GoogleFonts.poppins()),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  TextFieldThem.buildTextFiled(context,
                                      hintText: 'Account Number'.tr,
                                      controller: controller
                                          .accountNumberController.value),
                                  const SizedBox(
                                    height: 40,
                                  ),
                                  ButtonThem.buildButton(
                                    context,
                                    title: "Save".tr,
                                    onPress: () async {
                                      final bankName = controller
                                          .bankNameController.value.text
                                          .trim();
                                      final branchName = controller
                                          .branchNameController.value.text
                                          .trim();
                                      final holderName = controller
                                          .holderNameController.value.text
                                          .trim();
                                      final accountNumber = controller
                                          .accountNumberController.value.text
                                          .trim();

                                      // Validate all fields are not empty after trimming
                                      if (bankName.isEmpty) {
                                        ShowToastDialog.showToast(
                                            "Please enter bank name".tr);
                                        return;
                                      }
                                      if (branchName.isEmpty) {
                                        ShowToastDialog.showToast(
                                            "Please enter IFSC code".tr);
                                        return;
                                      }
                                      // Validate IFSC code (alphanumeric, 11 characters)
                                      if (!RegExp(r'^[A-Za-z0-9]{11}$')
                                          .hasMatch(branchName)) {
                                        ShowToastDialog.showToast(
                                            "IFSC code must be 11 alphanumeric characters"
                                                .tr);
                                        return;
                                      }
                                      if (holderName.isEmpty) {
                                        ShowToastDialog.showToast(
                                            "Please enter holder name".tr);
                                        return;
                                      }
                                      if (accountNumber.isEmpty) {
                                        ShowToastDialog.showToast(
                                            "Please enter account number".tr);
                                        return;
                                      }

                                      // Validate holder name (letters and spaces only)
                                      if (!RegExp(r'^[a-zA-Z\s]+$')
                                          .hasMatch(holderName)) {
                                        ShowToastDialog.showToast(
                                            "Holder name should contain only letters and spaces"
                                                .tr);
                                        return;
                                      }

                                      // Validate account number (9-18 digits)
                                      if (!RegExp(r'^\d{9,18}$')
                                          .hasMatch(accountNumber)) {
                                        ShowToastDialog.showToast(
                                            "Account number should be 9-18 digits"
                                                .tr);
                                        return;
                                      }

                                      ShowToastDialog.showLoader(
                                          "Please wait".tr);
                                      BankDetailsModel bankDetailsModel =
                                          controller.bankDetailsModel.value;

                                      bankDetailsModel.userId =
                                          FireStoreUtils.getCurrentUid();
                                      bankDetailsModel.bankName = bankName;
                                      bankDetailsModel.branchName = branchName;
                                      bankDetailsModel.holderName = holderName;
                                      bankDetailsModel.accountNumber =
                                          accountNumber;
                                      bankDetailsModel.otherInformation =
                                          controller.otherInformationController
                                              .value.text;

                                      await FireStoreUtils.updateBankDetails(
                                              bankDetailsModel)
                                          .then((value) {
                                        ShowToastDialog.closeLoader();
                                        ShowToastDialog.showToast(
                                            "Bank details update successfully"
                                                .tr);
                                      });
                                    },
                                  )
                                ],
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
