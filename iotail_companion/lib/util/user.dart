import 'dart:typed_data';

import 'package:iotail_companion/util/dog.dart';

class User {
  final String userID;
  final String name;
  final String email;
  final String phoneNumber;
  final Uint8List? profilePicture;
  final List<Dog> dogs;

  User(
      {required this.userID,
      required this.name,
      required this.email,
      required this.phoneNumber,
      this.profilePicture,
      required this.dogs});

  factory User.fromJson(Map<String, dynamic> json) {
    List<Dog> dogs = [];
    for (var dog in json["Dogs"]) {
      dogs.add(Dog.fromJson(dog));
    }
    return User(
      userID: json["UserID"],
      name: json["Name"],
      email: json["Email"],
      phoneNumber: json["PhoneNumber"],
      profilePicture: json["ProfilePicture"],
      dogs: dogs,
    );
  }
}
