import 'package:driver/controller/home_intercity_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:provider/provider.dart';

class HomeIntercityScreen extends StatelessWidget {
  const HomeIntercityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<HomeIntercityController>(
        init: HomeIntercityController(),
        dispose: (state) {
          FireStoreUtils().closeStream();
        },
        builder: (controller) {
          // Show the "Please fill your vehicle details" message only when the
          // selected service does NOT support intercity AND the driver has not
          // provided vehicle information. This allows drivers who selected
          // bike (or other non-car services) and have saved vehicle details to
          // use outstation features if appropriate.
          return (controller.selectedService.value.intercityType == null ||
                      controller.selectedService.value.intercityType ==
                          false) &&
                  controller.driverModel.value.vehicleInformation == null
              ? Scaffold(
                  backgroundColor: AppColors.primary,
                  body: Column(
                    children: [
                      SizedBox(
                        height: Responsive.width(8, context),
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
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Please fill your vehicle details".tr)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Scaffold(
                  body: controller.widgetOptions
                      .elementAt(controller.selectedIndex.value),
                  bottomNavigationBar: BottomNavigationBar(
                      items: <BottomNavigationBarItem>[
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset("assets/icons/ic_new.png",
                                width: 18,
                                color: controller.selectedIndex.value == 0
                                    ? (themeChange.getThem()
                                        ? Colors.white
                                        : AppColors.primary)
                                    : (themeChange.getThem()
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.grey)),
                          ),
                          label: 'New'.tr,
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset("assets/icons/ic_accepted.png",
                                width: 18,
                                color: controller.selectedIndex.value == 1
                                    ? (themeChange.getThem()
                                        ? Colors.white
                                        : AppColors.primary)
                                    : (themeChange.getThem()
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.grey)),
                          ),
                          label: 'Accepted'.tr,
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset("assets/icons/ic_active.png",
                                width: 18,
                                color: controller.selectedIndex.value == 2
                                    ? (themeChange.getThem()
                                        ? Colors.white
                                        : AppColors.primary)
                                    : (themeChange.getThem()
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.grey)),
                          ),
                          label: 'Active'.tr,
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset("assets/icons/ic_completed.png",
                                width: 18,
                                color: controller.selectedIndex.value == 3
                                    ? (themeChange.getThem()
                                        ? Colors.white
                                        : AppColors.primary)
                                    : (themeChange.getThem()
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.grey)),
                          ),
                          label: 'Completed'.tr,
                        ),
                      ],
                      backgroundColor: themeChange.getThem()
                          ? AppColors.darkModePrimary
                          : Colors.white,
                      type: BottomNavigationBarType.fixed,
                      currentIndex: controller.selectedIndex.value,
                      selectedItemColor: themeChange.getThem()
                          ? Colors.white
                          : AppColors.primary,
                      unselectedItemColor: themeChange.getThem()
                          ? Colors.white.withOpacity(0.5)
                          : Colors.grey,
                      selectedFontSize: 12,
                      unselectedFontSize: 12,
                      elevation: 5,
                      onTap: controller.onItemTapped),
                );
        });
  }
}
