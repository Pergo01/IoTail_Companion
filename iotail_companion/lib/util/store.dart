import 'kennel.dart';
import 'package:latlong2/latlong.dart';

class Store {
  final String name;
  final LatLng location;
  final List<Kennel> kennels;

  Store({required this.name, required this.location, required this.kennels});

  factory Store.fromJson(Map<String, dynamic> json) {
    List<Kennel> kennels = [];
    for (var kennel in json["Kennels"]) {
      kennels.add(Kennel.fromJson(kennel));
    }
    return Store(
      name: json["Name"],
      location: LatLng(json["Location"][0], json["Location"][1]),
      kennels: kennels,
    );
  }
}
