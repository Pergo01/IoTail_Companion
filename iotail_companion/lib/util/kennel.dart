class Kennel {
  final int ID;
  final String size;
  final bool booked;
  final bool occupied;

  Kennel(
      {required this.ID,
      required this.size,
      required this.booked,
      required this.occupied});

  factory Kennel.fromJson(Map<String, dynamic> json) {
    return Kennel(
      ID: json["ID"],
      size: json["Size"],
      booked: json["Booked"],
      occupied: json["Occupied"],
    );
  }
}
