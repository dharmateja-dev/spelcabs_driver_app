import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/controller/subscription_history_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SubscriptionHistoryScreen extends StatelessWidget {
  const SubscriptionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<SubscriptionHistoryController>(
        init: SubscriptionHistoryController(),
        builder: (controller) {
          return Scaffold(
              backgroundColor: themeChange.getThem()
                  ? AppColors.darkBackground
                  : AppColors.background,
              appBar: AppBar(
                title: Text(
                  "Purchase History".tr,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.primary,
                centerTitle: false,
                titleSpacing: 0,
                iconTheme: const IconThemeData(color: Colors.white, size: 20),
              ),
              body: controller.isLoading.value
                  ? Constant.loader(context)
                  : controller.subscriptionHistoryList.isEmpty
                      ? _buildEmptyView(context, themeChange)
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: controller.subscriptionHistoryList.length,
                          itemBuilder: (context, index) {
                            final subscriptionHistoryModel =
                                controller.subscriptionHistoryList[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: themeChange.getThem()
                                    ? AppColors.darkContainerBackground
                                    : AppColors.containerBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: themeChange.getThem()
                                      ? AppColors.darkContainerBorder
                                      : AppColors.containerBorder,
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x07000000),
                                    blurRadius: 20,
                                    offset: Offset(0, 0),
                                    spreadRadius: 0,
                                  )
                                ],
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: CachedNetworkImage(
                                                  imageUrl:
                                                      subscriptionHistoryModel
                                                              .subscriptionPlan
                                                              ?.image ??
                                                          '',
                                                  fit: BoxFit.cover,
                                                  width: 45,
                                                  height: 45,
                                                  placeholder: (context, url) =>
                                                      Container(
                                                    width: 45,
                                                    height: 45,
                                                    color: AppColors.lightGray,
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    ),
                                                  ),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Container(
                                                    width: 45,
                                                    height: 45,
                                                    color: AppColors.lightGray,
                                                    child: const Icon(
                                                        Icons.image,
                                                        size: 24),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  subscriptionHistoryModel
                                                          .subscriptionPlan
                                                          ?.name ??
                                                      '',
                                                  textAlign: TextAlign.start,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                    color: themeChange.getThem()
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (index == 0)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                  Icons.check_circle_outlined,
                                                  color: AppColors.ratingColour,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  'Active'.tr,
                                                  textAlign: TextAlign.start,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                    color:
                                                        AppColors.ratingColour,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Divider(
                                        color: themeChange.getThem()
                                            ? AppColors.darkContainerBorder
                                            : AppColors.containerBorder),
                                    const SizedBox(height: 5),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Validity'.tr,
                                                  textAlign: TextAlign.end,
                                                  maxLines: 2,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: themeChange.getThem()
                                                        ? AppColors
                                                            .subTitleColor
                                                        : AppColors
                                                            .subTitleColor,
                                                  )),
                                              Text(
                                                  subscriptionHistoryModel
                                                              .subscriptionPlan
                                                              ?.expiryDay ==
                                                          -1
                                                      ? "Unlimited".tr
                                                      : '${subscriptionHistoryModel.subscriptionPlan?.expiryDay ?? '0'}  Days',
                                                  textAlign: TextAlign.end,
                                                  maxLines: 2,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: themeChange.getThem()
                                                        ? Colors.white
                                                        : Colors.black,
                                                  )),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Price'.tr,
                                                  textAlign: TextAlign.end,
                                                  maxLines: 2,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: themeChange.getThem()
                                                        ? AppColors
                                                            .subTitleColor
                                                        : AppColors
                                                            .subTitleColor,
                                                  )),
                                              Text(
                                                  Constant.amountShow(
                                                      amount:
                                                          subscriptionHistoryModel
                                                                  .subscriptionPlan
                                                                  ?.price ??
                                                              '0'),
                                                  textAlign: TextAlign.end,
                                                  maxLines: 2,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: themeChange.getThem()
                                                        ? Colors.white
                                                        : Colors.black,
                                                  )),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Payment Type'.tr,
                                                  textAlign: TextAlign.end,
                                                  maxLines: 2,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: themeChange.getThem()
                                                        ? AppColors
                                                            .subTitleColor
                                                        : AppColors
                                                            .subTitleColor,
                                                  )),
                                              Text(
                                                  (subscriptionHistoryModel
                                                                  .paymentType ??
                                                              '')
                                                          .capitalizeFirst ??
                                                      '',
                                                  textAlign: TextAlign.end,
                                                  maxLines: 2,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: themeChange.getThem()
                                                        ? Colors.white
                                                        : Colors.black,
                                                  )),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Purchase Date'.tr,
                                                  textAlign: TextAlign.end,
                                                  maxLines: 2,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: themeChange.getThem()
                                                        ? AppColors
                                                            .subTitleColor
                                                        : AppColors
                                                            .subTitleColor,
                                                  )),
                                              Text(
                                                  _formatTimestamp(
                                                      subscriptionHistoryModel
                                                          .createdAt),
                                                  textAlign: TextAlign.end,
                                                  maxLines: 2,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: themeChange.getThem()
                                                        ? Colors.white
                                                        : Colors.black,
                                                  )),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Expiry Date'.tr,
                                                  textAlign: TextAlign.end,
                                                  maxLines: 2,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: themeChange.getThem()
                                                        ? AppColors
                                                            .subTitleColor
                                                        : AppColors
                                                            .subTitleColor,
                                                  )),
                                              Text(
                                                  subscriptionHistoryModel
                                                              .expiryDate ==
                                                          null
                                                      ? "Unlimited".tr
                                                      : _formatTimestamp(
                                                          subscriptionHistoryModel
                                                              .expiryDate),
                                                  textAlign: TextAlign.end,
                                                  maxLines: 2,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: themeChange.getThem()
                                                        ? Colors.white
                                                        : Colors.black,
                                                  )),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          }));
        });
  }

  Widget _buildEmptyView(BuildContext context, DarkThemeProvider themeChange) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: themeChange.getThem()
                ? AppColors.subTitleColor
                : AppColors.subTitleColor,
          ),
          const SizedBox(height: 16),
          Text(
            "Purchase History Not found".tr,
            style: TextStyle(
              fontSize: 16,
              color: themeChange.getThem() ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = timestamp.toDate();
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return '';
    }
  }
}
/*******************************************************************************************
* Copyright (c) 2025 Movenetics Digital. All rights reserved.
*
* This software and associated documentation files are the property of 
* Movenetics Digital. Unauthorized copying, modification, distribution, or use of this 
* Software, via any medium, is strictly prohibited without prior written permission.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
* INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
* PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
* LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT 
* OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
* OTHER DEALINGS IN THE SOFTWARE.
*
* Company: Movenetics Digital
* Author: Aman Bhandari 
*******************************************************************************************/
