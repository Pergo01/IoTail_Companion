class Breed {
  int breedID;
  String name;
  double? maxIdealTemperature;
  double? minIdealTemperature;
  double? maxIdealHumidity;
  double? minIdealHumidity;
  double? avgSize;
  double? avgWeight;
  String? coatType;

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
