import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver/utils/app_logger.dart';

/// Unified location permission helper for handling all location permission scenarios
/// Supports iOS 14+, Android 10+, and Android 12+ requirements
class LocationPermissionHelper {
  static const String _tag = "LocationPermissionHelper";

  /// Check and request location permission with educational UI
  /// Returns true if permission is granted (either when in use or always)
  static Future<bool> checkAndRequestLocationPermission({
    bool showEducationalDialog = true,
  }) async {
    try {
      // First check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showLocationServicesDisabledDialog();
        return false;
      }

      // Check current permission status
      final status = await Permission.location.status;
      AppLogger.info("Current location permission status: $status", tag: _tag);

      if (status.isGranted || status.isLimited) {
        // Permission already granted
        return true;
      } else if (status.isDenied) {
        // Show educational dialog if requested
        if (showEducationalDialog) {
          final shouldRequest = await _showPermissionEducationDialog();
          if (!shouldRequest) {
            return false;
          }
        }

        // Request permission
        final result = await Permission.location.request();
        AppLogger.info("Location permission request result: $result",
            tag: _tag);
        return result.isGranted || result.isLimited;
      } else if (status.isPermanentlyDenied) {
        // Permission permanently denied, guide user to settings
        await _showPermissionPermanentlyDeniedDialog();
        return false;
      } else if (status.isRestricted) {
        // Permission restricted (parental controls, etc.)
        _showToast("Location access is restricted on this device");
        return false;
      }

      return false;
    } catch (e, stackTrace) {
      AppLogger.error("Error checking location permission: $e",
          tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Request background location permission (Always Allow)
  /// This should be called after foreground permission is granted
  /// Returns true if background permission is granted
  static Future<bool> requestBackgroundLocationPermission() async {
    try {
      // Check if foreground permission is granted first
      final foregroundStatus = await Permission.location.status;
      if (!foregroundStatus.isGranted && !foregroundStatus.isLimited) {
        AppLogger.warning(
            "Foreground location permission not granted, cannot request background permission",
            tag: _tag);
        return false;
      }

      // Check if we're on a platform that supports background location
      if (Platform.isAndroid) {
        // Android 10+ requires separate background location permission
        final androidInfo = await _getAndroidVersion();
        if (androidInfo >= 29) {
          // Android 10+
          final backgroundStatus = await Permission.locationAlways.status;

          if (backgroundStatus.isGranted) {
            return true;
          } else if (backgroundStatus.isDenied) {
            // Show educational dialog for background permission
            final shouldRequest =
                await _showBackgroundPermissionEducationDialog();
            if (!shouldRequest) {
              return false;
            }

            final result = await Permission.locationAlways.request();
            AppLogger.info("Background location permission result: $result",
                tag: _tag);
            return result.isGranted;
          } else if (backgroundStatus.isPermanentlyDenied) {
            await _showPermissionPermanentlyDeniedDialog();
            return false;
          }
        }
      } else if (Platform.isIOS) {
        // iOS requires requesting "Always" permission
        final alwaysStatus = await Permission.locationAlways.status;

        if (alwaysStatus.isGranted) {
          return true;
        } else if (alwaysStatus.isDenied) {
          // Show educational dialog for background permission
          final shouldRequest =
              await _showBackgroundPermissionEducationDialog();
          if (!shouldRequest) {
            return false;
          }

          final result = await Permission.locationAlways.request();
          AppLogger.info("iOS Always location permission result: $result",
              tag: _tag);
          return result.isGranted;
        } else if (alwaysStatus.isPermanentlyDenied) {
          await _showPermissionPermanentlyDeniedDialog();
          return false;
        }
      }

      return false;
    } catch (e, stackTrace) {
      AppLogger.error("Error requesting background location permission: $e",
          tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Check if location services (GPS) are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current location permission status
  static Future<PermissionStatus> getLocationPermissionStatus() async {
    return await Permission.location.status;
  }

  /// Get background location permission status
  static Future<PermissionStatus>
      getBackgroundLocationPermissionStatus() async {
    return await Permission.locationAlways.status;
  }

  // ========== Private Helper Methods ==========

  /// Show educational dialog explaining why location permission is needed
  static Future<bool> _showPermissionEducationDialog() async {
    final completer = Completer<bool>();

    Get.dialog(
      AlertDialog(
        backgroundColor: Get.theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue[400], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Location Access Required',
                style: TextStyle(
                  color: Get.theme.textTheme.titleLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We need your location to:',
              style: TextStyle(
                color: Get.theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Show nearby ride requests'),
            _buildBulletPoint('Track your position during rides'),
            _buildBulletPoint('Provide accurate ETAs to customers'),
            _buildBulletPoint('Update your availability in real-time'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              completer.complete(false);
            },
            child: Text(
              'Not Now',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              completer.complete(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return completer.future;
  }

  /// Show educational dialog for background location permission
  static Future<bool> _showBackgroundPermissionEducationDialog() async {
    final completer = Completer<bool>();

    final String platformSpecificMessage = Platform.isIOS
        ? 'In the next dialog, please select "Always Allow" to enable background location tracking.'
        : 'Please allow background location access to track your position during rides.';

    Get.dialog(
      AlertDialog(
        backgroundColor: Get.theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.my_location, color: Colors.blue[400], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Background Location',
                style: TextStyle(
                  color: Get.theme.textTheme.titleLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To track your rides even when the app is in the background, we need continuous location access.',
              style: TextStyle(
                color: Get.theme.textTheme.bodyLarge?.color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                platformSpecificMessage,
                style: TextStyle(
                  color: Colors.blue[900],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This ensures customers can see your real-time location during active rides.',
              style: TextStyle(
                color: Get.theme.textTheme.bodyMedium?.color,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              completer.complete(false);
            },
            child: Text(
              'Not Now',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              completer.complete(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return completer.future;
  }

  /// Show dialog when permission is permanently denied
  static Future<void> _showPermissionPermanentlyDeniedDialog() async {
    await Get.dialog(
      AlertDialog(
        backgroundColor: Get.theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange[400], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Permission Required',
                style: TextStyle(
                  color: Get.theme.textTheme.titleLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Location permission is required to use this app. Please enable it in your device settings.',
          style: TextStyle(
            color: Get.theme.textTheme.bodyLarge?.color,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog when location services are disabled
  static Future<void> _showLocationServicesDisabledDialog() async {
    await Get.dialog(
      AlertDialog(
        backgroundColor: Get.theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.red[400], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Location Services Disabled',
                style: TextStyle(
                  color: Get.theme.textTheme.titleLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Please enable location services in your device settings to use this app.',
          style: TextStyle(
            color: Get.theme.textTheme.bodyLarge?.color,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a bullet point widget for permission education
  static Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Get.theme.textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show a simple toast message
  static void _showToast(String message) {
    Get.snackbar(
      'Notice',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      backgroundColor: Get.theme.snackBarTheme.backgroundColor,
      colorText: Get.theme.snackBarTheme.actionTextColor,
    );
  }

  /// Get Android API version
  static Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    // This is a simplified version - in production, you'd use device_info_plus
    // For now, we'll assume Android 10+ (API 29+) which is the minimum for this app
    return 29;
  }
}
