import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/model/driver_document_model.dart';
import 'package:driver/model/driver_rules_model.dart';
import 'package:driver/model/language_name.dart';
import 'package:driver/model/order/location_lat_lng.dart';
import 'package:driver/model/order/positions.dart';
import 'package:driver/model/subscription_plan_model.dart';

class DriverUserModel {
  String? phoneNumber;
  String? loginType;
  String? countryCode;
  String? profilePic;
  bool? documentVerification;
  String? fullName;
  bool? isOnline;
  String? id;
  String? serviceId;
  String? fcmToken;
  String? email;
  VehicleInformation? vehicleInformation;
  String? reviewsCount;
  String? reviewsSum;
  String? walletAmount;
  LocationLatLng? location;
  double? rotation;
  Positions? position;
  Timestamp? createdAt;
  List<dynamic>? zoneIds;

  // Subscription fields
  String? subscriptionPlanId;
  SubscriptionModel? subscriptionPlan;
  Timestamp? subscriptionExpiryDate;
  double? commission;

  List<Documents>? documents;
  Map<String, bool>? activeServices;

  DriverUserModel(
      {this.phoneNumber,
      this.loginType,
      this.countryCode,
      this.profilePic,
      this.documentVerification,
      this.fullName,
      this.isOnline,
      this.id,
      this.serviceId,
      this.fcmToken,
      this.email,
      this.location,
      this.vehicleInformation,
      this.reviewsCount,
      this.reviewsSum,
      this.rotation,
      this.position,
      this.walletAmount,
      this.createdAt,
      this.zoneIds,
      this.subscriptionPlanId,
      this.subscriptionPlan,
      this.subscriptionExpiryDate,
      this.commission,
      this.documents,
      this.activeServices});

  DriverUserModel.fromJson(Map<String, dynamic> json) {
    phoneNumber = json['phoneNumber'];
    loginType = json['loginType'];
    countryCode = json['countryCode'];
    profilePic = json['profilePic'] ?? '';
    documentVerification = json['documentVerification'];
    fullName = json['fullName'];
    isOnline = json['isOnline'];
    id = json['id'];
    serviceId = json['serviceId'];
    fcmToken = json['fcmToken'];
    email = json['email'];
    vehicleInformation = json['vehicleInformation'] != null
        ? VehicleInformation.fromJson(json['vehicleInformation'])
        : null;
    reviewsCount = json['reviewsCount'] ?? '0.0';
    reviewsSum = json['reviewsSum'] ?? '0.0';
    rotation = json['rotation'];
    walletAmount = json['walletAmount'] ?? "0.0";
    location = json['location'] != null
        ? LocationLatLng.fromJson(json['location'])
        : null;
    position =
        json['position'] != null ? Positions.fromJson(json['position']) : null;
    if (json['createdAt'] is int) {
      createdAt = Timestamp.fromMillisecondsSinceEpoch(json['createdAt']);
    } else if (json['createdAt'] is Timestamp) {
      createdAt = json['createdAt'];
    } else {
      createdAt = null;
    }
    zoneIds = json['zoneIds'];

    // Subscription fields
    subscriptionPlanId = json['subscriptionPlanId']?.toString();
    subscriptionPlan = json['subscriptionPlan'] != null
        ? SubscriptionModel.fromJson(
            json['subscriptionPlan'] is Map
                ? json['subscriptionPlan']
                : Map<String, dynamic>.from(json['subscriptionPlan']),
            json['subscriptionPlan']['id'])
        : null;
    subscriptionExpiryDate = json['subscriptionExpiryDate'] is Timestamp
        ? json['subscriptionExpiryDate']
        : (json['subscriptionExpiryDate'] != null &&
                json['subscriptionExpiryDate'] is int
            ? Timestamp.fromMillisecondsSinceEpoch(
                json['subscriptionExpiryDate'])
            : null);
    commission = json['commission'] != null
        ? (json['commission'] is double
            ? json['commission']
            : double.tryParse(json['commission'].toString()))
        : null;

    if (json['documents'] != null) {
      documents = <Documents>[];
      json['documents'].forEach((v) {
        documents!.add(Documents.fromJson(v));
      });
    }
    if (json['activeServices'] != null) {
      activeServices = Map<String, bool>.from(json['activeServices']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['phoneNumber'] = phoneNumber;
    data['loginType'] = loginType;
    data['countryCode'] = countryCode;
    data['profilePic'] = profilePic;
    data['documentVerification'] = documentVerification;
    data['fullName'] = fullName;
    data['isOnline'] = isOnline;
    data['id'] = id;
    data['serviceId'] = serviceId;
    data['fcmToken'] = fcmToken;
    data['email'] = email;
    data['rotation'] = rotation;
    data['createdAt'] = createdAt?.millisecondsSinceEpoch;
    if (vehicleInformation != null) {
      data['vehicleInformation'] = vehicleInformation!.toJson();
    }
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['reviewsCount'] = reviewsCount;
    data['reviewsSum'] = reviewsSum;
    data['walletAmount'] = walletAmount;
    data['zoneIds'] = zoneIds;
    if (position != null) {
      data['position'] = position!.toJson();
    }

    // Subscription fields
    data['subscriptionPlanId'] = subscriptionPlanId;
    if (subscriptionPlan != null) {
      data['subscriptionPlan'] = subscriptionPlan!.toJson();
    }
    data['subscriptionExpiryDate'] = subscriptionExpiryDate;
    data['commission'] = commission;

    if (documents != null) {
      data['documents'] = documents!.map((v) => v.toJson()).toList();
    }

    if (activeServices != null) {
      data['activeServices'] = activeServices;
    }

    return data;
  }
}

class VehicleInformation {
  List<LanguageName>? vehicleType;
  String? vehicleTypeId;
  Timestamp? registrationDate;
  String? vehicleColor;
  String? vehicleNumber;
  String? seats;
  List<DriverRulesModel>? driverRules;

  VehicleInformation(
      {this.vehicleType,
      this.vehicleTypeId,
      this.registrationDate,
      this.vehicleColor,
      this.vehicleNumber,
      this.seats,
      this.driverRules});

  VehicleInformation.fromJson(Map<String, dynamic> json) {
    if (json['vehicleType'] != null) {
      vehicleType = <LanguageName>[];
      json['vehicleType'].forEach((v) {
        vehicleType!.add(LanguageName.fromJson(v));
      });
    }
    vehicleTypeId = json['vehicleTypeId'];
    //EDIT: Handle registrationDate deserialization from int or Timestamp
    if (json['registrationDate'] is int) {
      registrationDate =
          Timestamp.fromMillisecondsSinceEpoch(json['registrationDate']);
    } else if (json['registrationDate'] is Timestamp) {
      registrationDate = json['registrationDate'];
    } else {
      registrationDate =
          null; // Ensure null if data is missing or unexpected type
    }
    vehicleColor = json['vehicleColor'];
    vehicleNumber = json['vehicleNumber'];
    seats = json['seats'];
    if (json['driverRules'] != null) {
      driverRules = <DriverRulesModel>[];
      json['driverRules'].forEach((v) {
        driverRules!.add(DriverRulesModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (vehicleType != null) {
      data['vehicleType'] = vehicleType!.map((v) => v.toJson()).toList();
    }
    data['vehicleTypeId'] = vehicleTypeId;
    data['registrationDate'] = registrationDate?.millisecondsSinceEpoch;
    data['vehicleColor'] = vehicleColor;
    data['vehicleNumber'] = vehicleNumber;
    data['seats'] = seats;
    if (driverRules != null) {
      data['driverRules'] = driverRules!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
