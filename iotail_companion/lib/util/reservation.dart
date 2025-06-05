/// Reservation class to represent a reservation for a dog in a kennel
class Reservation {
  final String userID; // User ID of the person making the reservation
  final String reservationID; // Unique ID for the reservation
  final String dogID; // ID of the dog being reserved
  final int kennelID; // ID of the kennel where the dog is reserved
  final int storeID; // ID of the store associated with the reservation
  final bool active; // Indicates if the reservation is currently active
  final int reservationTime; // Timestamp of when the reservation was made
  final int?
      activationTime; // Optional timestamp for when the reservation was activated

  Reservation({
    required this.userID,
    required this.reservationID,
    required this.dogID,
    required this.kennelID,
    required this.storeID,
    required this.active,
    required this.reservationTime,
    this.activationTime,
  });

  /// Converts a JSON object to a Reservation instance
  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
        userID: json['userID'],
        reservationID: json['reservationID'],
        dogID: json['dogID'],
        kennelID: json['kennelID'],
        storeID: json['storeID'],
        active: json['active'],
        reservationTime: json['reservationTime'],
        activationTime: json['activationTime']);
  }
}
