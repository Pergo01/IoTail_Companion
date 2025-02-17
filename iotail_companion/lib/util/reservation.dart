class Reservation {
  final String userID;
  final String reservationID;
  final String dogID;
  final int kennelID;
  final int storeID;
  final bool active;
  final int timestamp;

  Reservation({
    required this.userID,
    required this.reservationID,
    required this.dogID,
    required this.kennelID,
    required this.storeID,
    required this.active,
    required this.timestamp,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      userID: json['userID'],
      reservationID: json['reservationID'],
      dogID: json['dogID'],
      kennelID: json['kennelID'],
      storeID: json['storeID'],
      active: json['active'],
      timestamp: json['timestamp'],
    );
  }
}
