import 'package:driver/ui/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverLocationPermissionScreen extends StatefulWidget {
  const DriverLocationPermissionScreen({Key? key}) : super(key: key);

  @override
  State<DriverLocationPermissionScreen> createState() =>
      _DriverLocationPermissionScreenState();
}

class _DriverLocationPermissionScreenState
    extends State<DriverLocationPermissionScreen> {
  bool _isChecking = true;
  bool _needsDisclosure = false;
  bool _isRequestingPermission = false;
  bool _canNavigateAway = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final prefs = await SharedPreferences.getInstance();
      final hasCompletedDisclosure =
          prefs.getBool('driver_location_disclosure_completed') ?? false;

      print('🔍 Driver has completed disclosure: $hasCompletedDisclosure');

      if (hasCompletedDisclosure) {
        print('✅ Driver has completed disclosure, navigating to dashboard');
        _canNavigateAway = true;
        if (mounted) {
          _navigateToDashboard();
        }
      } else {
        print('🆕 First time driver, showing disclosure screen');
        if (mounted) {
          setState(() {
            _isChecking = false;
            _needsDisclosure = true;
          });
        }
      }
    } catch (e) {
      print('❌ Error checking permission: $e');

      if (mounted) {
        setState(() {
          _isChecking = false;
          _needsDisclosure = true;
        });
      }
    }
  }

  void _navigateToDashboard() {
    if (_canNavigateAway && mounted) {
      Get.offAll(() => const DashBoardScreen());
    }
  }

  Future<void> _markDisclosureCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('driver_location_disclosure_completed', true);
    print('✅ Marked driver disclosure as completed');
  }

  Future<void> _onAllowAccess() async {
    setState(() {
      _isRequestingPermission = true;
    });

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Requesting location permission...'),
                    SizedBox(height: 8),
                    Text(
                      'Please respond to the permission dialog',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        Get.back();
        setState(() {
          _isRequestingPermission = false;
        });
        _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.requestPermission();
      print('📱 Permission result: $permission');

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      setState(() {
        _isRequestingPermission = false;
      });

      await _markDisclosureCompleted();
      _canNavigateAway = true;

      if (permission == LocationPermission.denied) {
        Get.snackbar(
          'Permission Denied',
          'Location is required to receive ride requests',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          _navigateToDashboard();
        }
      } else if (permission == LocationPermission.deniedForever) {
        await _markDisclosureCompleted();
        _showPermissionPermanentlyDeniedDialog();
      } else {
        Get.snackbar(
          'Location Enabled',
          'You can now receive ride requests',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );

        _getCurrentLocation();

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _navigateToDashboard();
        }
      }
    } catch (e) {
      print('❌ Error requesting permission: $e');
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      setState(() {
        _isRequestingPermission = false;
      });
      await _markDisclosureCompleted();
      _canNavigateAway = true;
      if (mounted) {
        _navigateToDashboard();
      }
    }
  }

  void _onSkip() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(child: Text('Location Required')),
          ],
        ),
        content: const Text(
          'As a driver, you need to enable location access to:\n\n'
          '• Receive ride requests\n'
          '• Show your location to riders\n'
          '• Navigate to pickup/drop locations\n\n'
          'You can enable it later in settings, but you won\'t be able to accept rides without it.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _markDisclosureCompleted();
              _canNavigateAway = true;

              Get.snackbar(
                'Location Disabled',
                'Enable location in settings to accept rides',
                backgroundColor: Colors.grey[700],
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );

              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  _navigateToDashboard();
                }
              });
            },
            child: const Text('Skip Anyway'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _onAllowAccess();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xff193751)),
            child: const Text('Enable Location'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      print('✅ Driver Location: ${position.latitude}, ${position.longitude}');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('driver_last_latitude', position.latitude);
      await prefs.setDouble('driver_last_longitude', position.longitude);
    } catch (e) {
      print('❌ Error getting location: $e');
    }
  }

  void _showLocationServiceDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.location_off, color: Colors.red),
            SizedBox(width: 10),
            Expanded(child: Text('Location Services Disabled')),
          ],
        ),
        content: const Text(
          'Please enable GPS/Location services in your device settings to accept ride requests.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _onSkip();
            },
            child: const Text('Skip for Now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await Geolocator.openLocationSettings();

              await Future.delayed(const Duration(seconds: 2));

              bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
              if (serviceEnabled) {
                _onAllowAccess();
              } else {
                _onSkip();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xff193751)),
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 10),
            Expanded(child: Text('Permission Blocked')),
          ],
        ),
        content: const Text(
          'Location permission was permanently denied. To enable:\n\n'
          '1. Go to App Settings\n'
          '2. Find Permissions\n'
          '3. Enable Location (Allow all the time)\n'
          '4. Restart the app\n\n'
          'Note: You need location access to accept ride requests.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _canNavigateAway = true;
              _navigateToDashboard();
            },
            child: const Text('Continue Anyway'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await openAppSettings();
              await Future.delayed(const Duration(seconds: 1));
              _canNavigateAway = true;
              _navigateToDashboard();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xff193751)),
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _openPrivacyPolicy() {
    final Uri privacyPolicyUrl =
        Uri.parse('https://spelcabs.com/driver-policy/');
    launchUrl(privacyPolicyUrl, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Preparing Driver App...'),
            ],
          ),
        ),
      );
    }

    if (!_needsDisclosure) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xff193751).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.my_location,
                  size: 60,
                  color: Color(0xff193751),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Location Access Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Enable location to start accepting ride requests',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFeatureCard(
                        Icons.notifications_active,
                        'Receive Ride Requests',
                        'Get notified when riders near you request a ride',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        Icons.all_inclusive,
                        'Always-On Location Access',
                        'This app requires "Allow all the time" location permission to send you ride requests even when the app is in the background or closed. This ensures you never miss an opportunity to earn.',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        Icons.all_inclusive,
                        'Background location access is needed in a driver app to',
                        'Receive ride requests and navigate to pickups even when the app is not actively in use.',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        Icons.visibility,
                        'Show Your Location to Riders',
                        'Riders can see your real-time location for better coordination',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        Icons.navigation,
                        'Smart Navigation',
                        'Get turn-by-turn directions to pickup and drop-off locations',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        Icons.analytics,
                        'Accurate Trip Tracking',
                        'Automatically track trip distance for fair fare calculation',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        Icons.trending_up,
                        'Maximize Earnings',
                        'Stay online and available to accept more rides',
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xff193751).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Color(0xff193751).withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.privacy_tip,
                                    color: Color(0xff193751)),
                                SizedBox(width: 10),
                                Text(
                                  'Your Privacy Matters',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Your location is only used to:\n'
                              '• Match you with nearby riders\n'
                              '• Navigate during trips\n'
                              '• Track trip distances\n\n'
                              'We do not sell or share your location with third parties for advertising purposes.',
                              style: TextStyle(fontSize: 13, height: 1.5),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _openPrivacyPolicy,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'Read Privacy Policy',
                                    style: TextStyle(
                                      color: Color(0xff193751),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.open_in_new,
                                      size: 16, color: Color(0xff193751)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isRequestingPermission ? null : _onAllowAccess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff193751),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              // const SizedBox(height: 12),
              // TextButton(
              //   onPressed: _isRequestingPermission ? null : _onSkip,
              //   child: const Text(
              //     'Skip for Now',
              //     style: TextStyle(fontSize: 15, color: Colors.grey),
              //   ),
              // ),
              // const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xff193751).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Color(0xff193751), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
