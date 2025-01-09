import 'package:flutter_map/flutter_map.dart';

class DataMarker extends Marker {
  const DataMarker({
    required this.name,
    required this.isSuitable,
    required super.point,
    required super.child,
    super.height,
    super.width,
  });

  final String name;
  final bool isSuitable;
}
