import 'dart:convert';

// Helper function to decode JSON string into a PhonePe object.
PhonePe phonePeFromJson(String str) => PhonePe.fromJson(json.decode(str));

// Helper function to encode a PhonePe object into a JSON string.
String phonePeToJson(PhonePe data) => json.encode(data.toJson());

/// Represents the configuration model for PhonePe payment gateway.
/// This model will hold all necessary credentials and settings for PhonePe,
/// such as merchant ID, salt key, and sandbox/production environment flags.
class PhonePe {
  String? merchantId;
  String? saltKey;
  String? saltIndex;
  bool? enable;
  bool? isSandbox;
  String? name; // Display name for the payment method in the UI

  PhonePe({
    this.merchantId,
    this.saltKey,
    this.saltIndex,
    this.enable = false, // Default to disabled
    // this.isSandbox = false, // Default to production
    this.isSandbox = true, // Temporarily keeping it true till testing for the basic one is done.
    this.name,
  });

  /// Factory constructor to create a PhonePe instance from a JSON map.
  factory PhonePe.fromJson(Map<String, dynamic> json) => PhonePe(
    merchantId: json['merchantId'],
    saltKey: json['saltKey'],
    saltIndex: json['saltIndex'],
    enable: json['enable'],
    isSandbox: json['isSandbox'],
    name: json['name'],
  );

  /// Converts the PhonePe instance to a JSON map.
  Map<String, dynamic> toJson() => {
    'merchantId': merchantId,
    'saltKey': saltKey,
    'saltIndex': saltIndex,
    'enable': enable,
    'isSandbox': isSandbox,
    'name': name,
  };
}
