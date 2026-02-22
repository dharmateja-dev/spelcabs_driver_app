import 'package:cloud_firestore/cloud_firestore.dart';

/// Subscription plan model for driver subscriptions
class SubscriptionModel {
  String? id;
  String? name;
  String? description;
  String? image;
  String? type; // free / paid
  String? planFor; // driver / user
  bool? isEnable;
  bool? isActive; // for filtering active plans

  int? bookingLimit;
  int? driverLimit;
  int? place;

  String? expiryType; // monthly / yearly
  String? planType; // monthly / yearly (alias for expiryType)
  int? expiryValue;
  int? expiryDay;

  String? price; // stored as string in Firestore
  double? priceDouble; // for calculations
  List<String>? planPoints;

  Timestamp? createdAt;
  DateTime? createdAtDate;

  SubscriptionModel({
    this.id,
    this.name,
    this.description,
    this.image,
    this.type,
    this.planFor,
    this.isEnable,
    this.isActive,
    this.bookingLimit,
    this.driverLimit,
    this.place,
    this.expiryType,
    this.planType,
    this.expiryValue,
    this.expiryDay,
    this.price,
    this.priceDouble,
    this.planPoints,
    this.createdAt,
    this.createdAtDate,
  });

  /// 🔹 Firestore → Model
  factory SubscriptionModel.fromJson(Map<String, dynamic> json,
      [String? docId]) {
    final priceStr = json['price']?.toString() ?? '0';
    final expiryTypeValue = json['expiryType']?.toString() ?? '';

    return SubscriptionModel(
      id: docId ?? json['id'],
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      type: json['type']?.toString(),
      planFor: json['planFor']?.toString(),
      isEnable: json['isEnable'] == true || json['isEnable'] == 'true',
      isActive: json['isActive'] == true ||
          json['isActive'] == 'true' ||
          json['isEnable'] == true,
      bookingLimit: int.tryParse(json['bookingLimit']?.toString() ?? '0'),
      driverLimit: json['driverLimit'] == null
          ? null
          : int.tryParse(json['driverLimit'].toString()),
      place: int.tryParse(json['place']?.toString() ?? '0'),
      expiryType: expiryTypeValue,
      planType: expiryTypeValue, // alias
      expiryValue: int.tryParse(json['expiryValue']?.toString() ?? '0'),
      expiryDay: int.tryParse(json['expiryDay']?.toString() ?? '0'),
      price: priceStr,
      priceDouble: double.tryParse(priceStr),
      planPoints: json['plan_points'] != null
          ? List<String>.from(json['plan_points'])
          : [],
      createdAt: json['createdAt'] is Timestamp
          ? json['createdAt']
          : (json['createdAt'] != null
              ? (json['createdAt'] is int
                  ? Timestamp.fromMillisecondsSinceEpoch(json['createdAt'])
                  : Timestamp.fromDate(
                      DateTime.parse(json['createdAt'].toString())))
              : null),
      createdAtDate: json['createdAt'] is Timestamp
          ? json['createdAt'].toDate()
          : (json['createdAt'] != null
              ? (json['createdAt'] is int
                  ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
                  : DateTime.parse(json['createdAt'].toString()))
              : null),
    );
  }

  /// 🔹 Model → Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'type': type,
      'planFor': planFor,
      'isEnable': isEnable,
      'isActive': isActive ?? isEnable,
      'bookingLimit': bookingLimit?.toString(),
      'driverLimit': driverLimit,
      'place': place?.toString(),
      'expiryType': expiryType ?? planType,
      'expiryValue': expiryValue,
      'expiryDay': expiryDay?.toString(),
      'price': price ?? priceDouble?.toString(),
      'plan_points': planPoints,
      'createdAt': createdAt ??
          (createdAtDate != null ? Timestamp.fromDate(createdAtDate!) : null),
    };
  }
}

// Type aliases for backward compatibility
typedef SubscriptionPlanModel = SubscriptionModel;
typedef DriverSubscriptionModel = SubscriptionModel;
