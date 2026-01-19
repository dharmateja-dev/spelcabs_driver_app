import 'package:cloud_firestore/cloud_firestore.dart';

class Positions {
  String? geohash;
  GeoPoint? geoPoint;

  Positions({this.geohash, this.geoPoint});

  Positions.fromJson(Map<String, dynamic> json) {
    geohash = json['geohash'];
    //EDIT: Handle GeoPoint deserialization from a map if it was serialized as such
    if (json['geopoint'] is Map<String, dynamic>) {
      geoPoint = GeoPoint(json['geopoint']['latitude'], json['geopoint']['longitude']);
    } else if (json['geopoint'] is GeoPoint) {
      geoPoint = json['geopoint'];
    } else {
      geoPoint = null; // Handle cases where geopoint might be missing or unexpected type
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['geohash'] = geohash;
    //EDIT: Convert GeoPoint to its latitude and longitude for JSON serialization
    if (geoPoint != null) {
      data['geopoint'] = {
        'latitude': geoPoint!.latitude,
        'longitude': geoPoint!.longitude,
      };
    } else { //EDIT
      data['geopoint'] = null; //EDIT: Ensure null if geoPoint is not set
    } //EDIT
    return data;
  }
}
