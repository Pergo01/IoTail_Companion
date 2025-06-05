import 'dart:typed_data';

import 'package:iotail_companion/util/dog.dart';

/// User class
class User {
  final String userID; // Unique identifier for the user
  final String name; // Name of the user
  final String email; // Email address of the user
  final String phoneNumber; // Phone number of the user
  final Uint8List? profilePicture; // Optional profile picture of the user
  final List<Dog> dogs; // List of dogs owned by the user

  User(
      {required this.userID,
      required this.name,
      required this.email,
      required this.phoneNumber,
      this.profilePicture,
      required this.dogs});

  /// Converts a JSON object to a User instance
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
