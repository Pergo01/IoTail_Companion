import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

class Map extends StatefulWidget {
  final MqttServerClient client;
  const Map({Key? key, required this.client});

  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(44.890014050623655, 7.356047819388321),
            initialZoom: 16.5,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            ),
            CurrentLocationLayer(
              alignPositionOnUpdate: AlignOnUpdate.never,
              alignDirectionOnUpdate: AlignOnUpdate.never,
            )
          ]),
    );
  }
}
