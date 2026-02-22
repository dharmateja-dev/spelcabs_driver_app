import 'dart:async';
import 'dart:convert';

import 'package:driver/constant/constant.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/order/location_lat_lng.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/utils/app_logger.dart';
import 'package:driver/utils/preferences.dart';
import 'package:driver/ui/home_screens/order_map_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'dart:typed_data';

/// A singleton service that listens for new city ride orders and shows
/// local notifications regardless of which screen the driver is on.
///
/// This service runs as long as the driver is logged in and online.
class CityRidesListenerService {
  static final CityRidesListenerService _instance =
      CityRidesListenerService._internal();
  factory CityRidesListenerService() => _instance;
  CityRidesListenerService._internal();

  static const String _seenOrdersKey = 'seen_city_ride_order_ids';
  static const String _tag = 'CityRidesListenerService';

  /// Firestore stream subscription for orders
  StreamSubscription? _ordersSubscription;

  /// Set of order IDs we've already shown notifications for
  final Set<String> _seenOrderIds = {};

  /// Flag to track if service is currently listening
  bool _isListening = false;

  /// Local notifications plugin
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Current driver model reference
  DriverUserModel? _currentDriver;

  /// Current search location
  LocationLatLng? _currentLocation;

  /// Session start time - used to filter out old orders on app start
  DateTime? _sessionStartTime;

  /// Initialize the notification plugin
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: iosInitializationSettings,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Load previously seen order IDs from preferences
    await _loadSeenOrderIds();

    AppLogger.info('CityRidesListenerService initialized', tag: _tag);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info('Notification tapped with payload: ${response.payload}',
        tag: _tag);

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final orderId = data['orderId'];
        if (orderId != null) {
          AppLogger.info('Navigating to OrderMapScreen for order: $orderId',
              tag: _tag);
          Get.to(
            const OrderMapScreen(),
            arguments: {'orderModel': orderId},
          );
        }
      } catch (e) {
        AppLogger.error('Error parsing notification payload: $e',
            tag: _tag, error: e);
      }
    }
  }

  /// Start listening for new city rides
  ///
  /// Call this when the driver goes online or logs in
  void startListening({
    required DriverUserModel driver,
    required LocationLatLng location,
  }) {
    if (_isListening) {
      AppLogger.debug('Already listening, updating driver/location', tag: _tag);
      _currentDriver = driver;
      _currentLocation = location;
      return;
    }

    _currentDriver = driver;
    _currentLocation = location;

    if (!driver.isOnline!) {
      AppLogger.info('Driver is offline, not starting listener', tag: _tag);
      return;
    }

    // Set session start time to filter out orders created before this session
    _sessionStartTime = DateTime.now();
    AppLogger.info(
        'Starting city rides listener for driver: ${driver.id}, session start: $_sessionStartTime',
        tag: _tag);
    _isListening = true;

    _startOrdersStream();
  }

  /// Update the search location (call when driver moves significantly)
  void updateLocation(LocationLatLng newLocation) {
    if (_currentLocation == null ||
        _calculateDistance(_currentLocation!, newLocation) > 500) {
      _currentLocation = newLocation;
      AppLogger.debug('Location updated for city rides listener', tag: _tag);

      // Restart stream with new location if currently listening
      if (_isListening && _currentDriver != null) {
        _stopOrdersStream();
        _startOrdersStream();
      }
    }
  }

  /// Update driver online status
  void updateDriverStatus(DriverUserModel driver) {
    _currentDriver = driver;

    if (driver.isOnline == true && !_isListening && _currentLocation != null) {
      AppLogger.info('Driver went online, starting listener', tag: _tag);
      _isListening = true;
      _startOrdersStream();
    } else if (driver.isOnline == false && _isListening) {
      AppLogger.info('Driver went offline, stopping listener', tag: _tag);
      stopListening();
    }
  }

  /// Start the Firestore orders stream
  void _startOrdersStream() {
    if (_currentDriver == null || _currentLocation == null) {
      AppLogger.warning('Cannot start stream: driver or location is null',
          tag: _tag);
      return;
    }

    _ordersSubscription = FireStoreUtils()
        .getOrders(
      _currentDriver!,
      _currentLocation!.latitude,
      _currentLocation!.longitude,
    )
        .listen(
      _onOrdersReceived,
      onError: (error) {
        AppLogger.error('Error in orders stream: $error',
            tag: _tag, error: error);
      },
    );
  }

  /// Stop the Firestore orders stream
  void _stopOrdersStream() {
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
  }

  /// Handle new orders from the stream
  void _onOrdersReceived(List<OrderModel> orders) {
    AppLogger.debug('Received ${orders.length} orders from stream', tag: _tag);

    for (final order in orders) {
      if (order.id == null) continue;

      // Skip orders that were already seen
      if (_seenOrderIds.contains(order.id)) continue;

      // Skip orders created before this session started (prevents duplicate notifications)
      if (order.createdDate != null && _sessionStartTime != null) {
        try {
          final orderTime = order.createdDate!.toDate();
          if (orderTime.isBefore(_sessionStartTime!)) {
            AppLogger.debug(
                'Skipping old order ${order.id} created at $orderTime (before session $_sessionStartTime)',
                tag: _tag);
            _seenOrderIds.add(order.id!); // Mark as seen but don't notify
            continue;
          }
        } catch (e) {
          AppLogger.error('Error parsing order date: $e', tag: _tag, error: e);
        }
      }

      AppLogger.info('New order detected: ${order.id}', tag: _tag);
      _seenOrderIds.add(order.id!);
      _showNotification(order);
    }

    // Persist seen order IDs
    _saveSeenOrderIds();
  }

  /// Show local notification for a new order
  Future<void> _showNotification(OrderModel order) async {
    AppLogger.info('Showing notification for order: ${order.id}', tag: _tag);

    final Int64List vibrationPattern = Int64List(4);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 1000;
    vibrationPattern[2] = 500;
    vibrationPattern[3] = 1000;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'city_rides_channel',
      'City Rides',
      channelDescription: 'Notifications for new city ride requests',
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'New Ride Request',
      vibrationPattern: vibrationPattern,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Build notification content
    String title = 'New Ride Request'.tr;
    String body =
        'New ride from ${order.sourceLocationName ?? "pickup"} to ${order.destinationLocationName ?? "destination"}';

    if (order.offerRate != null) {
      body +=
          '\nAmount: ${Constant.amountShow(amount: order.offerRate.toString())}';
    }

    // Create payload with order info
    final payload = jsonEncode({
      'orderId': order.id,
      'type': 'city_ride',
    });

    await _notificationsPlugin.show(
      order.id.hashCode,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    AppLogger.info('Notification shown successfully for order: ${order.id}',
        tag: _tag);
  }

  /// Stop listening for orders
  void stopListening() {
    AppLogger.info('Stopping city rides listener', tag: _tag);
    _stopOrdersStream();
    _isListening = false;
  }

  /// Clear all data (call on logout)
  Future<void> clear() async {
    AppLogger.info('Clearing city rides listener service', tag: _tag);
    stopListening();
    _seenOrderIds.clear();
    _currentDriver = null;
    _currentLocation = null;

    // Clear persisted seen order IDs
    await Preferences.clearKeyData(_seenOrdersKey);
  }

  /// Load seen order IDs from preferences
  Future<void> _loadSeenOrderIds() async {
    try {
      final String storedIds = Preferences.getString(_seenOrdersKey);
      if (storedIds.isNotEmpty) {
        final List<dynamic> ids = jsonDecode(storedIds);
        _seenOrderIds.addAll(ids.cast<String>());
        AppLogger.debug('Loaded ${_seenOrderIds.length} seen order IDs',
            tag: _tag);
      }
    } catch (e) {
      AppLogger.error('Error loading seen order IDs: $e', tag: _tag, error: e);
    }
  }

  /// Save seen order IDs to preferences
  Future<void> _saveSeenOrderIds() async {
    try {
      // Keep only the last 100 order IDs to prevent unbounded growth
      final List<String> idsToSave = _seenOrderIds.toList();
      if (idsToSave.length > 100) {
        idsToSave.removeRange(0, idsToSave.length - 100);
        _seenOrderIds.clear();
        _seenOrderIds.addAll(idsToSave);
      }

      await Preferences.setString(_seenOrdersKey, jsonEncode(idsToSave));
    } catch (e) {
      AppLogger.error('Error saving seen order IDs: $e', tag: _tag, error: e);
    }
  }

  /// Calculate distance between two locations (in meters)
  double _calculateDistance(LocationLatLng loc1, LocationLatLng loc2) {
    // Simple approximation, good enough for our threshold check
    const double metersPerDegree = 111000;
    final double latDiff = (loc1.latitude! - loc2.latitude!).abs();
    final double lngDiff = (loc1.longitude! - loc2.longitude!).abs();
    return (latDiff + lngDiff) * metersPerDegree / 2;
  }

  /// Check if the service is currently listening
  bool get isListening => _isListening;
}
