import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_compass/flutter_map_compass.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';

import 'package:iotail_companion/UI/Material/dataMarkerPopup.dart';
import 'package:iotail_companion/util/dataMarker.dart';

class OSMMap extends StatefulWidget {
  final List<DataMarker> markerslist;
  final Function(DataMarker) onPrepareReservation;
  final VoidCallback onSubmitReservation;
  const OSMMap(
      {super.key,
      required this.markerslist,
      required this.onPrepareReservation,
      required this.onSubmitReservation});

  @override
  _OSMMapState createState() => _OSMMapState();
}

class _OSMMapState extends State<OSMMap> {
  final PopupController _popupController = PopupController();

  late AlignOnUpdate _alignPositionOnUpdate;
  late final StreamController<double?> _alignPositionStreamController;
  late FlutterSecureStorage storage;
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  final MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
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
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  spiderfyCluster: false,
                  spiderfyCircleRadius: widget.markerslist.length * 20,
                  spiderfySpiralDistanceMultiplier: 2,
                  circleSpiralSwitchover: 12,
                  maxClusterRadius: 120,
                  rotate: true,
                  size: const Size(40, 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(50),
                  maxZoom: 15,
                  markers: widget.markerslist,
                  onMarkerTap: (marker) {
                    widget.onPrepareReservation(marker as DataMarker);
                  },
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
                    /* markerTapBehavior: MarkerTapBehavior.custom(
                          (popupSpec, popupState, popupController) {
                            if (popupState.selectedPopupSpecs
                                .contains(popupSpec)) {
                              popupController.hideAllPopups();
                            } else {
                              popupController.showPopupsOnlyForSpecs([popupSpec]);
                            }
                          },
                        ), */
                    popupController: _popupController,
                    popupBuilder: (context, marker) {
                      if (marker is DataMarker) {
                        return Animate(
                            effects: const [
                              SlideEffect(
                                begin: Offset(0, 0.2),
                                end: Offset(0, 0),
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeIn,
                              ),
                            ],
                            child: DataMarkerPopup(
                              name: marker.name,
                              isSuitable: marker.isSuitable,
                              onReserve: () => {
                                widget.onSubmitReservation(),
                                _popupController.hideAllPopups()
                              },
                            ));
                      }
                      return const SizedBox();
                    },
                  ),
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
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: FloatingActionButton(
                    heroTag: "Center Position Button",
                    key: const Key("Center Position"),
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
              const MapCompass.cupertino(
                hideIfRotatedNorth:
                    true, // Hide the compass if the map is rotated north
              ), // Add a compass to the map
            ]),
      ),
    );
  }
}
