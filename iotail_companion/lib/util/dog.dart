import 'dart:typed_data';

/// Dog class with various attributes and a method to build it.
class Dog {
  final String dogID; // Unique identifier for the dog
  final String name; // Name of the dog
  final int breedID; // Identifier for the breed of the dog
  final int age; // Age of the dog in years
  final int sex; // 0 for male, 1 for female
  final String size; // Size of the dog (e.g., small, medium, large)
  final double weight; // Weight of the dog in kilograms
  final String coatType; // Type of coat the dog has (e.g., short, long, curly)
  final List<String> allergies; // List of allergies the dog has
  final Uint8List? picture; // Picture of the dog, stored as a byte array
  // Mixed Breed fields, they are null if the dog is of pure breed
  final double? maxIdealTemperature; // Maximum ideal temperature for the dog
  final double? minIdealTemperature; // Minimum ideal temperature for the dog
  final double? maxIdealHumidity; // Maximum ideal humidity for the dog
  final double? minIdealHumidity; // Minimum ideal humidity for the dog

  Dog(
      {required this.dogID,
      required this.name,
      required this.breedID,
      required this.age,
      required this.sex,
      required this.size,
      required this.weight,
      required this.coatType,
      required this.allergies,
      this.maxIdealTemperature,
      this.minIdealTemperature,
      this.maxIdealHumidity,
      this.minIdealHumidity,
      this.picture});

  /// Converts a JSON object to a Dog instance.
  factory Dog.fromJson(Map<String, dynamic> json) {
    List<String> allergies = [];
    for (var allergy in json["Allergies"]) {
      allergies.add(allergy);
    }
    return Dog(
      dogID: json["DogID"],
      name: json["Name"],
      breedID: json["BreedID"],
      age: json["Age"],
      sex: json["Sex"] == 0 ? 0 : 1,
      size: json["Size"],
      weight: double.parse(json["Weight"].toString()),
      coatType: json["CoatType"],
      allergies: allergies,
      maxIdealTemperature: json["MaxIdealTemperature"] == null
          ? null
          : double.parse(json["MaxIdealTemperature"].toString()),
      minIdealTemperature: json["MinIdealTemperature"] == null
          ? null
          : double.parse(json["MinIdealTemperature"].toString()),
      maxIdealHumidity: json["MaxIdealHumidity"] == null
          ? null
          : double.parse(json["MaxIdealHumidity"].toString()),
      minIdealHumidity: json["MinIdealHumidity"] == null
          ? null
          : double.parse(json["MinIdealHumidity"].toString()),
      picture: json["Picture"],
    );
  }
}
