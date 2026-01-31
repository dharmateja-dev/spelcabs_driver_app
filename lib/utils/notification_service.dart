import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/intercity_order_model.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/ui/chat_screen/chat_screen.dart';
import 'package:driver/ui/home_screens/order_map_screen.dart';
import 'package:driver/ui/order_intercity_screen/complete_intecity_order_screen.dart';
import 'package:driver/ui/order_screen/complete_order_screen.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
  log("BackGround Message :: ${message.messageId}");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  RemoteNotification? notification = message.notification;
  if (notification == null && message.data.isNotEmpty) {
    // Determine title and body from data if notification payload is missing
    String title = "New Notification";
    String body = "You have a new update";

    // Customize based on your data structure, e.g., for bookings
    if (message.data.containsKey('title')) {
      title = message.data['title'];
    }
    if (message.data.containsKey('body')) {
      body = message.data['body'];
    }
    // Fallback for specific order types if title/body not in data
    if (message.data['type'] == 'city_order') {
      title = "New City Ride";
      body = "You have a new city ride request";
    }

    notification = RemoteNotification(title: title, body: body);
  }

  if (notification != null) {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosInitializationSettings = const DarwinInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: iosInitializationSettings);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    AndroidNotificationChannel channel = const AndroidNotificationChannel(
      '0',
      'goRide-driver',
      description: 'Show GoRide Notification',
      importance: Importance.max,
    );
    AndroidNotificationDetails notificationDetails = AndroidNotificationDetails(
        channel.id, channel.name,
        channelDescription: 'your channel Description',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker');
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true);
    NotificationDetails notificationDetailsBoth = NotificationDetails(
        android: notificationDetails, iOS: darwinNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      notification.title,
      notification.body,
      notificationDetailsBoth,
      payload: jsonEncode(message.data),
    );
  }
}

class NotificationService {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  initInfo() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    var request = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    log("Notification authorization status: ${request.authorizationStatus}");
    if (request.authorizationStatus == AuthorizationStatus.authorized ||
        request.authorizationStatus == AuthorizationStatus.provisional ||
        Platform.isAndroid) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      var iosInitializationSettings = const DarwinInitializationSettings();
      final InitializationSettings initializationSettings =
          InitializationSettings(
              android: initializationSettingsAndroid,
              iOS: iosInitializationSettings);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onDidReceiveNotificationResponse: (payload) {
        log("Notification clicked with payload: $payload");
      });
      log("Local notifications initialized.");
      setupInteractedMessage();
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessageBackgroundHandle);
  }

  void setupInteractedMessage() async {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        log("Initial Message :: ${message.messageId}");
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("::::::::::::onMessage RECEIVE:::::::::::::::::");
      log("Message ID: ${message.messageId}");
      if (message.notification != null || message.data.isNotEmpty) {
        log("Data: ${message.data}");
        display(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      log("::::::::::::onMessageOpenedApp:::::::::::::::::");
      if (message.notification != null) {
        log(message.data.toString());
        // display(message);
        if (message.data['type'] == "city_order") {
          Get.to(const OrderMapScreen(),
              arguments: {"orderModel": message.data['orderId']});
        } else if (message.data['type'] == "city_order_payment_complete") {
          OrderModel? orderModel =
              await FireStoreUtils.getOrder(message.data['orderId']);
          Get.to(const CompleteOrderScreen(), arguments: {
            "orderModel": orderModel,
          });
        } else if (message.data['type'] == "intercity_order_payment_complete") {
          InterCityOrderModel? orderModel =
              await FireStoreUtils.getInterCityOrder(message.data['orderId']);
          Get.to(const CompleteIntercityOrderScreen(), arguments: {
            "orderModel": orderModel,
          });
        } else if (message.data['type'] == "chat") {
          UserModel? customer =
              await FireStoreUtils.getCustomer(message.data['customerId']);
          DriverUserModel? driver =
              await FireStoreUtils.getDriverProfile(message.data['driverId']);

          Get.to(ChatScreens(
            driverId: driver!.id,
            customerId: customer!.id,
            customerName: customer.fullName,
            customerProfileImage: customer.profilePic,
            driverName: driver.fullName,
            driverProfileImage: driver.profilePic,
            orderId: message.data['orderId'],
            token: customer.fcmToken,
          ));
        }
      }
    });

    await FirebaseMessaging.instance.subscribeToTopic("goRide_driver");
    await FirebaseMessaging.instance.subscribeToTopic("global");
    log("Subscribed to topics: goRide_driver, global");
  }

  static getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    return token!;
  }

  void display(RemoteMessage message) async {
    log('Got a message whilst in the foreground!');

    String title = "New Notification";
    String body = "You have a new update";

    if (message.notification != null) {
      title = message.notification!.title ?? title;
      body = message.notification!.body ?? body;
    } else if (message.data.isNotEmpty) {
      if (message.data.containsKey('title')) {
        title = message.data['title'];
      }
      if (message.data.containsKey('body')) {
        body = message.data['body'];
      }
      if (message.data['type'] == 'city_order') {
        title = "New City Ride";
        body = "You have a new city ride request";
      }
    }

    log('Message body: $body');

    try {
      AndroidNotificationChannel channel = const AndroidNotificationChannel(
        'goRide_notification',
        'GoRide Notifications',
        description: 'Critical ride requests and updates',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final Int64List vibrationPattern = Int64List(4);
      vibrationPattern[0] = 0;
      vibrationPattern[1] = 1000;
      vibrationPattern[2] = 500;
      vibrationPattern[3] = 1000;

      AndroidNotificationDetails notificationDetails =
          AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.max,
        priority: Priority.max,
        ticker: 'ticker',
        vibrationPattern: vibrationPattern,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
              presentAlert: true, presentBadge: true, presentSound: true);
      NotificationDetails notificationDetailsBoth = NotificationDetails(
          android: notificationDetails, iOS: darwinNotificationDetails);

      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        notificationDetailsBoth,
        payload: jsonEncode(message.data),
      );
      log("Notification shown successfully on channel: ${channel.id}");
    } on Exception catch (e) {
      log("Error showing notification: ${e.toString()}");
    }
  }
}
