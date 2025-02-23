class Breed {
  int breedID;
  String name;
  double maxIdealTemperature;
  double minIdealTemperature;
  double maxIdealHumidity;
  double minIdealHumidity;
  double avgSize;
  double avgWeight;
  String coatType;

  Breed({
    required this.breedID,
    required this.name,
    required this.maxIdealTemperature,
    required this.minIdealTemperature,
    required this.maxIdealHumidity,
    required this.minIdealHumidity,
    required this.avgSize,
    required this.avgWeight,
    required this.coatType,
  });

  factory Breed.fromJson(Map<String, dynamic> json) {
    return Breed(
      breedID: json['BreedID'],
      name: json['Name'],
      maxIdealTemperature: (json['MaxIdealTemperature'] as num).toDouble(),
      minIdealTemperature: (json['MinIdealTemperature'] as num).toDouble(),
      maxIdealHumidity: (json['MaxIdealHumidity'] as num).toDouble(),
      minIdealHumidity: (json['MinIdealHumidity'] as num).toDouble(),
      avgSize: (json['AvgSize'] as num).toDouble(),
      avgWeight: (json['AvgWeight'] as num).toDouble(),
      coatType: json['CoatType'],
    );
  }
}
