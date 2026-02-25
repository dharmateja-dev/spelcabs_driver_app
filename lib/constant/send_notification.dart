// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:driver/constant/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class SendNotification {
  static final _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  static Future getCharacters() {
    return http
        .get(Uri.parse(Constant.jsonNotificationFileURL.toString()))
        .catchError((e) async {
      try {
        await FirebaseFirestore.instance.collection('notification_debug').add({
          'createdAt': FieldValue.serverTimestamp(),
          'stage': 'getCharacters_error',
          'error': e.toString(),
          'url': Constant.jsonNotificationFileURL,
        });
      } catch (_) {}
      throw e;
    });
  }

  static Future<String> getAccessToken() async {
    Map<String, dynamic> jsonData = {};

    await getCharacters().then((response) {
      try {
        jsonData = json.decode(response.body);
      } catch (e) {
        // Log invalid JSON
        FirebaseFirestore.instance.collection('notification_debug').add({
          'createdAt': FieldValue.serverTimestamp(),
          'stage': 'service_json_decode_error',
          'error': e.toString(),
          'body': response.body,
        });
        rethrow;
      }
    });
    final serviceAccountCredentials =
        ServiceAccountCredentials.fromJson(jsonData);

    final client =
        await clientViaServiceAccount(serviceAccountCredentials, _scopes);
    return client.credentials.accessToken.data;
  }

  static Future<bool> sendOneNotification(
      {required String token,
      required String title,
      required String body,
      required Map<String, dynamic> payload,
      String? driverName}) async {
    try {
      if (token.isEmpty) {
        debugPrint(
            "[SendNotification] WARNING: FCM token is empty! Notification will not be sent.");
        debugPrint("[SendNotification] Title: $title, Body: $body");
        return false;
      }

      final String accessToken = await getAccessToken();
      debugPrint(
          "[SendNotification] Sending notification to token: ${token.substring(0, 20)}...");
      debugPrint("[SendNotification] Title: $title");

      final Map<String, dynamic> finalPayload = {};
      finalPayload.addAll(payload);
      if (driverName != null && driverName.isNotEmpty) {
        finalPayload['driverName'] = driverName;
      }

      final response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/${Constant.senderId}/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(
          <String, dynamic>{
            'message': {
              'token': token,
              'notification': {'body': body, 'title': title},
              'data': finalPayload,
            }
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint(
            "[SendNotification] SUCCESS: Notification sent (${response.statusCode})");
        try {
          await FirebaseFirestore.instance.collection('notification_logs').add({
            'createdAt': FieldValue.serverTimestamp(),
            'token': token,
            'title': title,
            'body': body,
            'payload': finalPayload,
            'status': response.statusCode,
            'response': response.body,
            'success': true,
          });
        } catch (e) {
          debugPrint('[SendNotification] Log save failed: $e');
        }
      } else {
        debugPrint("[SendNotification] FAILED: Status ${response.statusCode}");
        debugPrint("[SendNotification] Response: ${response.body}");
        try {
          await FirebaseFirestore.instance.collection('notification_logs').add({
            'createdAt': FieldValue.serverTimestamp(),
            'token': token,
            'title': title,
            'body': body,
            'payload': finalPayload,
            'status': response.statusCode,
            'response': response.body,
            'success': false,
          });
        } catch (e) {
          debugPrint('[SendNotification] Log save failed: $e');
        }
      }
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("[SendNotification] ERROR: $e");
      try {
        await FirebaseFirestore.instance.collection('notification_logs').add({
          'createdAt': FieldValue.serverTimestamp(),
          'token': token,
          'title': title,
          'body': body,
          'payload': payload,
          'error': e.toString(),
          'success': false,
        });
      } catch (_) {}
      return false;
    }
  }

  static Future<void> sendMultiPleNotification(List<String> tokens,
      String title, String body, Map<String, dynamic>? payload) async {
    final String accessToken = await getAccessToken();
    debugPrint("accessToken=======>");
    debugPrint(accessToken);

    final response = await http.post(
      Uri.parse(
          'https://fcm.googleapis.com/v1/projects/${Constant.senderId}/messages:send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'message': {
            'token': tokens,
            'notification': {'body': body, 'title': title},
            'data': payload,
          }
        },
      ),
    );

    debugPrint("Notification=======>");
    debugPrint(response.statusCode.toString());
    debugPrint(response.body);
  }
}
