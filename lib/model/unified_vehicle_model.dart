import 'package:driver/model/language_name.dart';

class UnifiedVehicleModel {
  String name;
  String image;
  String? passengerServiceId;
  String? freightServiceId;
  List<LanguageName>? rawNames;

  // Helper to check if it's dual-purpose
  bool get isDual => passengerServiceId != null && freightServiceId != null;

  UnifiedVehicleModel(
      {required this.name,
      required this.image,
      this.passengerServiceId,
      this.freightServiceId,
      this.rawNames});
}
