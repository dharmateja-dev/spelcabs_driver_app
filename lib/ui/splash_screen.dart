import 'package:driver/controller/splash_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetX<SplashController>(
        init: SplashController(),
        builder: (controller) {
          // Show retry UI when navigation failed
          if (controller.navigationFailed.value) {
            return Scaffold(
              backgroundColor: AppColors.primary,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset("assets/app_logo2.png", width: 200),
                    const SizedBox(height: 20),
                    const Text(
                      "Failed to load. Please try again.",
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: controller.retryRedirect,
                      child: const Text("Retry"),
                    )
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.primary,
            body:
                Center(child: Image.asset("assets/app_logo2.png", width: 200)),
          );
        });
  }
}
