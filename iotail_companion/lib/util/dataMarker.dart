import 'package:flutter_map/flutter_map.dart';

/// A custom marker class for storing data for points on a Flutter map. Extends Marker class
class DataMarker extends Marker {
  final String name; // Name of the marker
  final bool
      isSuitable; // Indicates if the marker is suitable for a specific purpose
  final int id; // Unique identifier for the marker

  const DataMarker({
    required this.id,
    required this.name,
    required this.isSuitable,
    required super.point,
    required super.child,
    super.height,
    super.width,
  });
}
