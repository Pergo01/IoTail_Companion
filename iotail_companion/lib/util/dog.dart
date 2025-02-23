import 'dart:typed_data';

class Dog {
  final String dogID;
  final String name;
  final int breedID;
  final int age;
  final int sex; // 0 for male, 1 for female
  final String size;
  final double weight;
  final String coatType;
  final List<String> allergies;
  final Uint8List? picture;
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
      this.picture});

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
      picture: json["Picture"],
    );
  }
}
