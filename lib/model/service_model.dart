import 'package:driver/model/admin_commission.dart';
import 'package:driver/model/language_title.dart';

class ServiceModel {
  String? image;
  bool? enable;
  bool? offerRate;
  bool? intercityType;
  String? id;
  List<LanguageTitle>? title;
  List<ZonePrice>? prices;
  String? acCharge;
  String? nonAcCharge;
  String? basicFareCharge;
  bool? isAcNonAc;
  String? kmCharge;
  AdminCommission? adminCommission;

  ServiceModel(
      {this.image,
      this.enable,
      this.intercityType,
      this.offerRate,
      this.id,
      this.title,
      this.kmCharge,
      this.adminCommission,
      this.prices,
      this.acCharge,
      this.nonAcCharge,
      this.basicFareCharge,
      this.isAcNonAc});

  ServiceModel.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    enable = json['enable'];
    offerRate = json['offerRate'];
    id = json['id'];
    kmCharge = json['kmCharge'];
    intercityType = json['intercityType'];
    acCharge = json['acCharge'];
    nonAcCharge = json['nonAcCharge'];
    basicFareCharge = json['basicFareCharge'];
    isAcNonAc = json['isAcNonAc'];
    adminCommission = json['adminCommission'] != null
        ? AdminCommission.fromJson(json['adminCommission'])
        : AdminCommission(isEnabled: true, amount: "", type: "");
    if (json['title'] != null) {
      title = <LanguageTitle>[];
      json['title'].forEach((v) {
        title!.add(LanguageTitle.fromJson(v));
      });
    }
    if (json['prices'] != null) {
      prices = <ZonePrice>[];
      json['prices'].forEach((v) {
        prices!.add(ZonePrice.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['image'] = image;
    data['enable'] = enable;
    data['offerRate'] = offerRate;
    data['id'] = id;
    data['title'] = title;
    data['kmCharge'] = kmCharge;
    data['intercityType'] = intercityType;
    data['acCharge'] = acCharge;
    data['nonAcCharge'] = nonAcCharge;
    data['basicFareCharge'] = basicFareCharge;
    data['isAcNonAc'] = isAcNonAc;
    if (title != null) {
      data['title'] = title!.map((v) => v.toJson()).toList();
    }
    if (prices != null) {
      data['prices'] = prices!.map((v) => v.toJson()).toList();
    }
    if (adminCommission != null) {
      data['adminCommission'] = adminCommission!.toJson();
    }
    return data;
  }
}

class ZonePrice {
  String? zoneId;
  String? kmCharge;
  String? acCharge;
  String? nonAcCharge;
  String? basicFareCharge;

  ZonePrice(
      {this.zoneId,
      this.kmCharge,
      this.acCharge,
      this.nonAcCharge,
      this.basicFareCharge});

  ZonePrice.fromJson(Map<String, dynamic> json) {
    zoneId = json['zoneId'];
    kmCharge = json['kmCharge'];
    acCharge = json['acCharge'];
    nonAcCharge = json['nonAcCharge'];
    basicFareCharge = json['basicFareCharge'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['zoneId'] = zoneId;
    data['kmCharge'] = kmCharge;
    data['acCharge'] = acCharge;
    data['nonAcCharge'] = nonAcCharge;
    data['basicFareCharge'] = basicFareCharge;
    return data;
  }
}
