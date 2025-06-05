/// Breed class to represent a dog breed with various attributes
class Breed {
  int breedID; // Unique identifier for the breed
  String name; // Name of the breed

  // All the following attributes are not present in a mixed breed, so they are nullable
  double? maxIdealTemperature; // Maximum ideal temperature for the breed
  double? minIdealTemperature; // Minimum ideal temperature for the breed
  double? maxIdealHumidity; // Maximum ideal humidity for the breed
  double? minIdealHumidity; // Minimum ideal humidity for the breed
  double? avgSize; // Average size of the breed
  double? avgWeight; // Average weight of the breed
  String? coatType; // Type of coat the breed has (e.g., short, long, curly)

  Breed({
    required this.breedID,
    required this.name,
    this.maxIdealTemperature,
    this.minIdealTemperature,
    this.maxIdealHumidity,
    this.minIdealHumidity,
    this.avgSize,
    this.avgWeight,
    this.coatType,
  });

  /// Converts a JSON map to a Breed object
  factory Breed.fromJson(Map<String, dynamic> json) {
    return Breed(
      breedID: json['BreedID'],
      name: json['Name'],
      maxIdealTemperature: json['MaxIdealTemperature'] == null
          ? null
          : double.parse(json['MaxIdealTemperature'].toString()),
      minIdealTemperature: json['MinIdealTemperature'] == null
          ? null
          : double.parse(json['MinIdealTemperature'].toString()),
      maxIdealHumidity: json['MaxIdealHumidity'] == null
          ? null
          : double.parse(json['MaxIdealHumidity'].toString()),
      minIdealHumidity: json['MinIdealHumidity'] == null
          ? null
          : double.parse(json['MinIdealHumidity'].toString()),
      avgSize: json['AvgSize'] == null
          ? null
          : double.parse(json['AvgSize'].toString()),
      avgWeight: json['AvgWeight'] == null
          ? null
          : double.parse(json['AvgWeight'].toString()),
      coatType: json['CoatType'] ?? json['CoatType'],
    );
  }
}
