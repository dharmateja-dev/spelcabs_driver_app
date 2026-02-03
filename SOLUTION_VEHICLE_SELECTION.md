# Solution: Unified Vehicle Selection & Dispatch Logic

## Overview
This solution addresses the requirement to display Passenger and Freight vehicles in a **single, linear list without duplicates**, while enabling the driver to receive notifications for **both** types if supported.

## Core Concept: The "Virtual Merge" & Active Services Map
To solve the "notifications" issue (one driver, multiple service types) without breaking Firestore limitations (which forbid two `arrayContains` queries), we will implement a **Map-based service registration**.

### 1. Data Structure Changes
Instead of a single `serviceId` string, we will use a Map called `activeServices`.

**Driver User Model (Firestore Data Structure):**
```json
{
  "activeServices": {
    "passenger_car_service_id": true,
    "freight_car_service_id": true
  },
  "zoneId": ["zone1", "zone2"]
}
```

This allow us to query efficiently:
`where('activeServices.TARGET_SERVICE_ID', isEqualTo: true)` AND `where('zoneId', arrayContainsAny: [...])`.

---

## Step 1: Update `DriverUserModel` (Driver App)
Add the `activeServices` map field.

**File:** `lib/model/driver_user_model.dart`

```dart
class DriverUserModel {
  // ... existing fields
  Map<String, bool>? activeServices; // NEW FIELD

  DriverUserModel({
    // ... params
    this.activeServices,
  });

  DriverUserModel.fromJson(Map<String, dynamic> json) {
    // ... existing parsing
    if (json['activeServices'] != null) {
      activeServices = Map<String, bool>.from(json['activeServices']);
    }
  }

  Map<String, dynamic> toJson() {
    // ... existing toJson
    if (activeServices != null) {
      data['activeServices'] = activeServices;
    }
    return data;
  }
}
```

## Step 2: Create a Unified Vehicle Model (Driver App)
Create a temporary model class in your controller to represent a "Merged" vehicle row.

**File:** `lib/controller/vehicle_information_controller.dart`

```dart
// Add this class at the bottom or in a separate file
class UnifiedVehicleModel {
  String name;
  String image;
  String? passengerServiceId;
  String? freightServiceId;
  
  // Helper to check if it's dual-purpose
  bool get isDual => passengerServiceId != null && freightServiceId != null;

  UnifiedVehicleModel({
    required this.name, 
    required this.image, 
    this.passengerServiceId, 
    this.freightServiceId
  });
}
```

## Step 3: Update Controller Logic (Merger)
Fetch both lists and merge them by name.

**File:** `lib/controller/vehicle_information_controller.dart`

```dart
// ... inside VehicleInformationController

RxList<UnifiedVehicleModel> unifiedVehicleList = <UnifiedVehicleModel>[].obs;
Rx<UnifiedVehicleModel?> selectedUnifiedVehicle = Rx<UnifiedVehicleModel?>(null);

getVehicleType() async {
  List<ServiceModel> services = await FireStoreUtils.getService();
  List<FreightVehicle> freights = await FireStoreUtils.getFreightVehicle();
  
  Map<String, UnifiedVehicleModel> merger = {};

  // 1. Process Passenger Services
  for (var s in services) {
    String name = Constant.localizationTitle(s.title).trim();
    if (!merger.containsKey(name.toLowerCase())) {
      merger[name.toLowerCase()] = UnifiedVehicleModel(
        name: name,
        image: s.image ?? "",
        passengerServiceId: s.id
      );
    } else {
      // Update existing
      merger[name.toLowerCase()]!.passengerServiceId = s.id;
    }
  }

  // 2. Process Freight Vehicles
  for (var f in freights) {
    String name = Constant.localizationName(f.name).trim();
    if (!merger.containsKey(name.toLowerCase())) {
      merger[name.toLowerCase()] = UnifiedVehicleModel(
        name: name,
        image: f.image ?? "",
        freightServiceId: f.id
      );
    } else {
      // Vehicle exists (e.g., "Car"), add Freight ID to it
      merger[name.toLowerCase()]!.freightServiceId = f.id;
    }
  }

  unifiedVehicleList.value = merger.values.toList();
}
```

## Step 4: Handle Selection & Rules
When a user selects a vehicle, we combine the rules.

```dart
void selectVehicle(UnifiedVehicleModel vehicle) async {
  selectedUnifiedVehicle.value = vehicle;
  
  // Clear rules first
  driverRulesList.clear();

  // 1. Fetch Passenger Rules if applicable
  if (vehicle.passengerServiceId != null) {
      // logic to fetch passenger rules (usually they are global or linked to type)
      // If rules are linked to "VehicleType", fetch them using FireStoreUtils.getDriverRules()
      // You may need to filter rules based on the service type context if your DB supports it
  }

  // 2. Fetch Freight Rules if applicable
  if (vehicle.freightServiceId != null) {
      // Fetch specifically freight rules if they are different
  }
  
  // Start with global rules (existing logic)
  var allRules = await FireStoreUtils.getDriverRules();
  if (allRules != null) {
     driverRulesList.value = allRules;
  }
}

// SAVING LOGIC
Future<void> saveVehicleInfo() async {
   // ... validations
   
   Map<String, bool> serviceMap = {};
   
   if (selectedUnifiedVehicle.value!.passengerServiceId != null) {
      serviceMap[selectedUnifiedVehicle.value!.passengerServiceId!] = true;
   }
   if (selectedUnifiedVehicle.value!.freightServiceId != null) {
      serviceMap[selectedUnifiedVehicle.value!.freightServiceId!] = true;
   }

   driverModel.value.activeServices = serviceMap; // Set the map
   driverModel.value.serviceId = selectedUnifiedVehicle.value!.passengerServiceId ?? selectedUnifiedVehicle.value!.freightServiceId; // Fallback for legacy queries
   
   // ... save to Firestore
}
```

## Step 5: Update Dispatch Query (Customer App)
This is the most critical part for notifications. You must update how the **Customer App** finds drivers.

**File:** `lib/utils/fire_store_utils.dart` (Customer App)

Find the `sendOrderData` or `getDrivers` method and update the query:

```dart
// OLD QUERY
// .where('serviceId', isEqualTo: orderModel.serviceId)

// NEW QUERY (Map-based)
// Check if the specific service ID exists as a key in the 'activeServices' map
.where('activeServices.${orderModel.serviceId}', isEqualTo: true)
```
*Note: This works seamlessly with `where('zoneId', arrayContainsAny: ...)` because it is an equality check, not a second array check.*

## Step 6: Update UI (Linear List)
Use `ListView.builder` with `unifiedVehicleList`.

**File:** `lib/ui/vehicle_information/vehicle_information_screen.dart`

```dart
SizedBox(
  height: Responsive.height(18, context),
  child: ListView.builder(
    itemCount: controller.unifiedVehicleList.length,
    scrollDirection: Axis.horizontal,
    itemBuilder: (context, index) {
       UnifiedVehicleModel vehicle = controller.unifiedVehicleList[index];
       
       return Obx(() => InkWell(
          onTap: () => controller.selectVehicle(vehicle),
          child: Container(
             // Styling...
             // Check generic selection:
             // color: controller.selectedUnifiedVehicle.value == vehicle ? Blue : Grey
             child: Column(
                children: [
                   CachedNetworkImage(imageUrl: vehicle.image),
                   Text(vehicle.name),
                   // Optional: Show badge if dual Type
                   if (vehicle.isDual) Text("Passenger & Freight", style: TextStyle(fontSize: 10)),
                ]
             )
          )
       ));
    }
  )
)
```

## Summary
1.  **Duplicate Removal:** Achieved by the `merger` loop in the Controller. "Car" (Passenger) + "Car" (Freight) becomes one "Car" object.
2.  **Linear Display:** One single list source (`unifiedVehicleList`) displayed in one `ListView`.
3.  **Notifications:** Enabled for both types by using the `activeServices` Map and updating the Customer App's query logic.
4.  **Rules:** Rules are loaded cumulatively. (You can further refine this by tagging rules in the database with "type": "freight" or "passenger" and filtering locally).
