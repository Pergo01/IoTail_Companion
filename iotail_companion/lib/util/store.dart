import 'kennel.dart';
import 'package:latlong2/latlong.dart';

/// Store class to represent a store with its name, ID, location, and kennels
class Store {
  final String name; // Name of the store
  final int id; // Unique ID for the store
  final LatLng
      location; // Location of the store represented as latitude and longitude
  final List<Kennel> kennels; // List of kennels available in the store

  Store(
      {required this.name,
      required this.id,
      required this.location,
      required this.kennels});

  /// Converts a JSON object to a Store instance
  factory Store.fromJson(Map<String, dynamic> json) {
    List<Kennel> kennels = [];
    for (var kennel in json["Kennels"]) {
      kennels.add(Kennel.fromJson(kennel));
    }
    return Store(
      name: json["Name"],
      id: json["StoreID"],
      location: LatLng(json["Location"][0], json["Location"][1]),
      kennels: kennels,
    );
  }
}
