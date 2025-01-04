class Dog {
  String dogID;
  String name;
  String breed;
  int age;
  int sex; // 0 for male, 1 for female
  double size;
  double weight;
  String coatType;
  List<String> allergies;
  Dog(
      {required this.dogID,
      required this.name,
      required this.breed,
      required this.age,
      required this.sex,
      required this.size,
      required this.weight,
      required this.coatType,
      required this.allergies});
  factory Dog.fromJson(Map<String, dynamic> json) {
    List<String> allergies = [];
    for (var allergy in json["Allergies"]) {
      allergies.add(allergy);
    }
    return Dog(
      dogID: json["DogID"],
      name: json["Name"],
      breed: json["Breed"],
      age: json["Age"],
      sex: json["Sex"] == 0 ? 0 : 1,
      size: json["Size"].toDouble(),
      weight: json["Weight"].toDouble(),
      coatType: json["CoatType"],
      allergies: allergies,
    );
  }
}
