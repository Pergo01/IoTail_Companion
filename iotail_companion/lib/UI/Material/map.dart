import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

class Map extends StatefulWidget {
  final MqttServerClient client;
  const Map({Key? key, required this.client});

  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  final PopupController _popupController = PopupController();

  late AlignOnUpdate _alignPositionOnUpdate;
  late final StreamController<double?> _alignPositionStreamController;
  late List<Marker> markers;

  final MapController mapController = MapController();

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
    final isDarkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    markers = [
      Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: const LatLng(44.88635, 7.33861),
        child: Icon(
          Icons.pets,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: const LatLng(44.88487, 7.33523),
        child: Icon(
          Icons.pets,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: const LatLng(44.881874, 7.331156),
        child: Icon(
          Icons.pets,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: const LatLng(44.88601, 7.33707),
        child: Icon(
          Icons.pets,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ];
    return Center(
      child: PopupScope(
        popupController: _popupController,
        child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter:
                  const LatLng(44.890014050623655, 7.356047819388321),
              initialZoom: 16.5,
              onTap: (_, __) => _popupController.hideAllPopups(),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                tileBuilder: isDarkTheme ? darkModeTileBuilder : null,
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  spiderfyCluster: false,
                  spiderfyCircleRadius: markers.length * 20,
                  spiderfySpiralDistanceMultiplier: 2,
                  circleSpiralSwitchover: 12,
                  maxClusterRadius: 120,
                  rotate: true,
                  size: const Size(40, 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(50),
                  maxZoom: 15,
                  markers: markers,
                  onClusterTap: (cluster) {
                    final latLngs =
                        cluster.markers.map((m) => m.point).toList();
                    final bounds = LatLngBounds.fromPoints(latLngs);
                    mapController.fitCamera(
                      CameraFit.bounds(
                          bounds: bounds, padding: const EdgeInsets.all(50)),
                    );
                  },
                  polygonOptions: PolygonOptions(
                      borderColor: Theme.of(context).colorScheme.tertiary,
                      color: Colors.black12,
                      borderStrokeWidth: 3),
                  popupOptions: PopupOptions(
                      popupSnap: PopupSnap.markerTop,
                      popupAnimation: const PopupAnimation.fade(),
                      //provare qua a riposizionare i popup
                      markerTapBehavior: MarkerTapBehavior.custom(
                        (popupSpec, popupState, popupController) {
                          if (popupState.selectedPopupSpecs
                              .contains(popupSpec)) {
                            popupController.hideAllPopups();
                          } else {
                            popupController.showPopupsOnlyForSpecs([popupSpec]);
                          }
                        },
                      ),
                      popupController: _popupController,
                      popupBuilder: (_, marker) => Animate(
                            effects: const [
                              SlideEffect(
                                begin: Offset(0, 0.2),
                                end: Offset(0, 0),
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeIn,
                              ),
                            ],
                            child: Card(
                              elevation: 3,
                              child: Container(
                                width: 200,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: GestureDetector(
                                  onTap: () => _popupController.hideAllPopups(),
                                  child: const Text(
                                    'Container popup for marker',
                                  ),
                                ),
                              ),
                            ),
                          )),
                  builder: (context, markers) {
                    return Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Theme.of(context).colorScheme.tertiary),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onTertiary),
                        ),
                      ),
                    );
                  },
                ),
              ),
              CurrentLocationLayer(
                alignPositionStream: _alignPositionStreamController.stream,
                alignPositionOnUpdate: _alignPositionOnUpdate,
                alignDirectionOnUpdate: AlignOnUpdate.never,
                style: LocationMarkerStyle(
                  showHeadingSector: false,
                  marker: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 2,
                        color: Colors.white,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      radius: 10,
                    ),
                  ),
                  accuracyCircleColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: FloatingActionButton(
                    shape: const CircleBorder(),
                    onPressed: () {
                      setState(
                        () => _alignPositionOnUpdate = AlignOnUpdate.once,
                      );
                      _alignPositionStreamController.add(16.5);
                    },
                    child: Icon(
                      Icons.my_location,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ]),
      ),
    );
  }
}
