import 'dart:async';

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
  late AlignOnUpdate _alignPositionOnUpdate;
  late final StreamController<double?> _alignPositionStreamController;

  @override
  void initState() {
    super.initState();
    _alignPositionOnUpdate = AlignOnUpdate.once;
    _alignPositionStreamController = StreamController<double?>();
  }

  @override
  void dispose() {
    _alignPositionStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Center(
      child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(44.890014050623655, 7.356047819388321),
            initialZoom: 16.5,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              tileBuilder: isDarkTheme ? darkModeTileBuilder : null,
            ),
            CurrentLocationLayer(
              alignPositionStream: _alignPositionStreamController.stream,
              alignPositionOnUpdate: _alignPositionOnUpdate,
              alignDirectionOnUpdate: AlignOnUpdate.never,
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: FloatingActionButton(
                  onPressed: () {
                    // Align the location marker to the center of the map widget
                    // on location update until user interact with the map.
                    setState(
                      () => _alignPositionOnUpdate = AlignOnUpdate.once,
                    );
                    // Align the location marker to the center of the map widget
                    // and zoom the map to level 18.
                    _alignPositionStreamController.add(18);
                  },
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ]),
    );
  }
}
