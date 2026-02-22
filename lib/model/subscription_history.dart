import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/model/subscription_plan_model.dart';

class SubscriptionHistoryModel {
  String? id;
  String? userId;
  Timestamp? expiryDate;
  Timestamp? createdAt;
  SubscriptionModel? subscriptionPlan;
  String? paymentType;

  SubscriptionHistoryModel({
    this.id,
    this.userId,
    this.expiryDate,
    this.createdAt,
    this.subscriptionPlan,
    this.paymentType,
  });

  factory SubscriptionHistoryModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return SubscriptionHistoryModel(
      id: docId ?? json['id'],
      userId: json['user_id'] ?? json['userId'],
      expiryDate: json['expiry_date'] is Timestamp 
          ? json['expiry_date'] 
          : (json['expiry_date'] != null ? Timestamp.fromDate(DateTime.parse(json['expiry_date'].toString())) : null),
      createdAt: json['createdAt'] is Timestamp 
          ? json['createdAt'] 
          : (json['createdAt'] != null ? Timestamp.fromDate(DateTime.parse(json['createdAt'].toString())) : null),
      subscriptionPlan: json['subscription_plan'] != null
          ? SubscriptionModel.fromJson(
              json['subscription_plan'] is Map 
                  ? json['subscription_plan'] 
                  : Map<String, dynamic>.from(json['subscription_plan']),
              json['subscription_plan']['id']
            )
          : null,
      paymentType: json['payment_type']?.toString() ?? json['paymentType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'expiry_date': expiryDate,
      'createdAt': createdAt,
      'subscription_plan': subscriptionPlan?.toJson(),
      'payment_type': paymentType?.toString(),
    };
  }
}
/*******************************************************************************************
* Copyright (c) 2025 Movenetics Digital. All rights reserved.
*
* This software and associated documentation files are the property of 
* Movenetics Digital. Unauthorized copying, modification, distribution, or use of this 
* Software, via any medium, is strictly prohibited without prior written permission.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
* INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
* PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
* LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT 
* OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
* OTHER DEALINGS IN THE SOFTWARE.
*
* Company: Movenetics Digital
* Author: Aman Bhandari 
*******************************************************************************************/
