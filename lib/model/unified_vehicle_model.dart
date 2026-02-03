class UnifiedVehicleModel {
  String name;
  String image;
  String? passengerServiceId;
  String? freightServiceId;

  // Helper to check if it's dual-purpose
  bool get isDual => passengerServiceId != null && freightServiceId != null;

  UnifiedVehicleModel(
      {required this.name,
      required this.image,
      this.passengerServiceId,
      this.freightServiceId});
}
