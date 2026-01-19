import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:driver/themes/app_colors.dart'; // Assuming you have this for consistent theming

/// A screen to display the PhonePe payment gateway in a WebView.
/// It handles loading the payment URL and detecting payment status based on redirects.
class PhonePeScreen extends StatefulWidget {
  final String initialURl;
  final String successUrl; // URL to listen for successful payment
  final String failureUrl; // URL to listen for failed payment

  const PhonePeScreen({
    super.key,
    required this.initialURl,
    required this.successUrl,
    required this.failureUrl,
  });

  @override
  State<PhonePeScreen> createState() => _PhonePeScreenState();
}

class _PhonePeScreenState extends State<PhonePeScreen> {
  WebViewController controller = WebViewController();
  bool isLoading = true; // State to manage loading indicator visibility

  @override
  void initState() {
    super.initState();
    initController();
  }

  /// Initializes the WebViewController with necessary settings and navigation delegates.
  void initController() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Allow JavaScript execution
      ..setBackgroundColor(const Color(0x00000000)) // Transparent background
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // You can use this to show a linear progress indicator if needed
            debugPrint('WebView is loading (progress: $progress%)');
          },
          onPageStarted: (String url) {
            // Show loader when page starts loading
            setState(() {
              isLoading = true;
            });
            log('Page started loading: $url');
          },
          onPageFinished: (String url) {
            // Hide loader when page finishes loading
            setState(() {
              isLoading = false;
            });
            log('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            // Handle any web resource loading errors
            log('Web resource error: ${error.description}');
            // Optionally, navigate back with a failure result
            Navigator.of(context).pop(false);
          },
          onNavigationRequest: (NavigationRequest navigation) async {
            log('Navigating to: ${navigation.url}');

            // Check if the navigation URL contains the success URL
            if (navigation.url.contains(widget.successUrl)) {
              log('Payment Success detected: ${navigation.url}');
              // Navigate back and indicate success
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent; // Prevent further navigation
            }
            // Check if the navigation URL contains the failure URL
            else if (navigation.url.contains(widget.failureUrl)) {
              log('Payment Failure detected: ${navigation.url}');
              // Navigate back and indicate failure
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent; // Prevent further navigation
            }
            // Allow other navigations
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialURl)); // Load the initial PhonePe payment URL
  }

  /// Shows a confirmation dialog when the user tries to go back.
  /// This prevents accidental cancellation of payments.
  Future<void> _showCancelPaymentDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // User can tap outside to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Payment'.tr),
          content: SingleChildScrollView(
            child: Text("Are you sure you want to cancel this payment?".tr),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'No'.tr, // Changed to "No" for continuing payment
                style: const TextStyle(color: Colors.green),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog, stay on payment screen
              },
            ),
            TextButton(
              child: Text(
                'Yes'.tr, // Changed to "Yes" for canceling payment
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                Get.back(result: false); // Go back to previous screen with a false result (canceled)
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // `canPop: false` prevents the default back navigation.
      canPop: false,
      // `onPopInvoked` is called when a pop gesture or back button is invoked.
      // `didPop` is true if the pop succeeded, false otherwise.
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          // If the pop was not handled by the system (i.e., we prevented it with canPop: false),
          // then show our custom dialog.
          _showCancelPaymentDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "PhonePe Payment".tr,
            style: const TextStyle(color: Colors.white), // Consistent with wallet screen
          ),
          centerTitle: false, // Consistent with wallet screen
          backgroundColor: AppColors.primary, // Consistent with wallet screen
          leading: GestureDetector(
            onTap: () {
              _showCancelPaymentDialog(); // Show dialog on back arrow tap
            },
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: controller), // The WebView displaying PhonePe
            Visibility(
              visible: isLoading, // Show loading indicator
              child: const Center(
                child: CircularProgressIndicator(), // Standard loading spinner
              ),
            ),
          ],
        ),
      ),
    );
  }
}
