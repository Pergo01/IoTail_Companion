/// Kennel with attributes and a method to build it.
class Kennel {
  final int ID; // Unique identifier for the kennel
  final String size; // Size of the kennel (e.g., "Small", "Medium", "Large")
  final bool booked; // Indicates if the kennel is booked
  final bool occupied; // Indicates if the kennel is currently occupied

  Kennel(
      {required this.ID,
      required this.size,
      required this.booked,
      required this.occupied});

  /// Converts a JSON object to a Kennel instance.
  factory Kennel.fromJson(Map<String, dynamic> json) {
    return Kennel(
      ID: json["ID"],
      size: json["Size"],
      booked: json["Booked"],
      occupied: json["Occupied"],
    );
  }
}
