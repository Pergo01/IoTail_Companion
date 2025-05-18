import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holdable_button/holdable_button.dart';
import 'package:holdable_button/utils/utils.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:slide_countdown/slide_countdown.dart';

import 'package:iotail_companion/util/reservation.dart';
import 'package:iotail_companion/util/dog.dart';
import 'package:iotail_companion/util/requests.dart' as requests;

class ReservationScreen extends StatefulWidget {
  final Reservation reservation;
  final Dog dog;
  final String ip;
  final MqttServerClient client;
  final VoidCallback onReservationCancel;

  const ReservationScreen(
      {super.key,
      required this.reservation,
      required this.dog,
      required this.ip,
      required this.client,
      required this.onReservationCancel});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  bool showCamera = false;
  late final WebViewController webController;
  late Future<bool> isCameraReady;
  late Future<List<double>> tempHumid;
  late Future<Map> kennelMeasurements;

  Future<bool> waitForCamera() async {
    bool camera = false;
    await Future.delayed(Duration(seconds: 4), () {
      webController.reload();
      webController.enableZoom(false);
    }).then((val) => camera = true);
    return camera;
  }

  Future<List<double>> getTemperatureHumidity() async {
    List<double> tmp = await requests.getTemperatureHumidity(widget.ip);
    return tmp;
  }

  Future<Map> getKennelMeasurements() async {
    // int initTime = max(widget.reservation.activationTime!,
    //     (DateTime.now().millisecondsSinceEpoch / 1000).round() - 600);
    Map data = await requests.getKennelmeasurements(widget.ip,
        widget.reservation.kennelID, widget.reservation.activationTime!);
    return data;
  }

  @override
  void initState() {
    super.initState();
    tempHumid = getTemperatureHumidity();
    kennelMeasurements = getKennelMeasurements();
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
            ''');
          },
        ),
      )
      ..loadRequest(Uri.parse('http://${widget.ip}:8090/camera_0'));
  }

  @override
  Widget build(BuildContext context) {
    DateTime startTime = DateTime.fromMillisecondsSinceEpoch(
        widget.reservation.activationTime! * 1000);
    Duration remainingTime = DateTime.now().difference(startTime);
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          forceMaterialTransparency: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Theme.of(context).colorScheme.inversePrimary,
                Theme.of(context).colorScheme.tertiary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Text(
              'IoTail',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: RefreshIndicator(
              onRefresh: () async {
                webController.reload();
                setState(() {
                  tempHumid = getTemperatureHumidity();
                  kennelMeasurements = getKennelMeasurements();
                });
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dog: ${widget.dog.name}",
                          style: TextStyle(fontSize: 40),
                        ),
                        Text(
                          "Kennel: ${widget.reservation.kennelID}",
                          style: TextStyle(fontSize: 30),
                        ),
                        Text(
                          "Activated at: ${DateTime.fromMillisecondsSinceEpoch(widget.reservation.activationTime! * 1000, isUtc: false).hour.toString().padLeft(2, '0')}:${DateTime.fromMillisecondsSinceEpoch(widget.reservation.activationTime! * 1000, isUtc: false).minute.toString().padLeft(2, '0')}",
                          style: TextStyle(fontSize: 20),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "Time since activation: ",
                              style: TextStyle(fontSize: 20),
                            ),
                            SlideCountdown(
                              duration: remainingTime,
                              countUp: true,
                              infinityCountUp: true,
                              countUpAtDuration: true,
                              slideDirection: SlideDirection.down,
                              separator: ":",
                              separatorStyle: TextStyle(fontSize: 20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                              ),
                              style: const TextStyle(fontSize: 20),
                            )
                          ],
                        ),
                        Stack(alignment: Alignment.center, children: [
                          Container(
                            height: 200,
                            width: MediaQuery.of(context).size.width,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8)),
                            // Set a fixed height for the WebView
                            child: showCamera
                                ? FutureBuilder(
                                    future: isCameraReady,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Container(
                                          clipBehavior: Clip.hardEdge,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: WebViewWidget(
                                            controller: webController,
                                          ),
                                        );
                                      }
                                      return Center(
                                          child: CircularProgressIndicator());
                                    },
                                  )
                                : Container(),
                          ),
                          if (!showCamera)
                            ElevatedButton(
                                style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all(
                                        Theme.of(context).colorScheme.primary),
                                    foregroundColor: WidgetStateProperty.all(
                                        Theme.of(context)
                                            .colorScheme
                                            .onPrimary)),
                                onPressed: () async {
                                  final builder = MqttPayloadBuilder();
                                  builder
                                      .addString(jsonEncode({"message": "on"}));
                                  widget.client.publishMessage(
                                      "IoTail/kennel1/camera",
                                      MqttQos.exactlyOnce,
                                      builder.payload!);
                                  if (!showCamera) {
                                    setState(() {
                                      showCamera = !showCamera;
                                    });
                                    isCameraReady = waitForCamera();
                                  } else {
                                    setState(() {
                                      showCamera = !showCamera;
                                    });
                                  }
                                },
                                child: const Text("Show camera")),
                          if (showCamera)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      showCamera = !showCamera;
                                    });
                                    final builder = MqttPayloadBuilder();
                                    builder.addString(
                                        jsonEncode({"message": "off"}));
                                    widget.client.publishMessage(
                                        "IoTail/kennel1/camera",
                                        MqttQos.exactlyOnce,
                                        builder.payload!);
                                  },
                                  icon: Icon(Icons.close)),
                            )
                        ]),
                        Divider(
                          thickness: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const Text(
                          "Current environment measurements:",
                          style: TextStyle(fontSize: 25),
                        ),
                        FutureBuilder(
                            future: tempHumid,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          "Temperature: ${snapshot.data![0]}°C",
                                          style: TextStyle(fontSize: 20)),
                                      Text("Humidity: ${snapshot.data![1]}%",
                                          style: TextStyle(fontSize: 20)),
                                    ]);
                              }
                              if (snapshot.hasError) {
                                return Text(
                                    "Error: Unable to fetch data from sensors");
                              }
                              return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Temperature: ...°C",
                                        style: TextStyle(fontSize: 20)),
                                    Text("Humidity: ...%",
                                        style: TextStyle(fontSize: 20)),
                                  ]);
                            }),
                        Divider(
                          thickness: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        FutureBuilder(
                            future: kennelMeasurements,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text("Error: ${snapshot.error}");
                              }
                              if (snapshot.hasData) {
                                // Trova min e max temperatura per l'asse Y
                                final List<Map> temperatures = List<Map>.from(
                                    snapshot.data!["temperature"]);
                                final List<Map> humidities =
                                    List<Map>.from(snapshot.data!["humidity"]);

                                if (temperatures.isEmpty &&
                                    humidities.isEmpty) {
                                  return const Center(
                                      child: Text(
                                          "Nessun dato di misurazione disponibile."));
                                }

                                double minY = 0,
                                    maxY = 0,
                                    minH = 0,
                                    maxH = 0,
                                    paddingY = 1,
                                    paddingH = 1;
                                double intervalX = 60000 * 15,
                                    intervalXH = 60000 * 15;

                                if (temperatures.isNotEmpty) {
                                  minY = temperatures
                                      .map<double>((e) => e["value"].toDouble())
                                      .reduce((a, b) => a < b ? a : b);
                                  maxY = temperatures
                                      .map<double>((e) => e["value"].toDouble())
                                      .reduce((a, b) => a > b ? a : b);
                                  paddingY = (maxY - minY) * 0.1;
                                  if (paddingY < 1) paddingY = 0.5;
                                  minY -= paddingY;
                                  maxY += paddingY;
                                  final firstTimestamp = (temperatures
                                          .first["timestamp"] as DateTime)
                                      .millisecondsSinceEpoch
                                      .toDouble();
                                  final lastTimestamp = (temperatures
                                          .last["timestamp"] as DateTime)
                                      .millisecondsSinceEpoch
                                      .toDouble();
                                  intervalX = (lastTimestamp > firstTimestamp)
                                      ? (lastTimestamp - firstTimestamp) / 7
                                      : 60000 * 15;
                                }

                                if (humidities.isNotEmpty) {
                                  minH = humidities
                                      .map<double>((e) => e["value"].toDouble())
                                      .reduce((a, b) => a < b ? a : b);
                                  maxH = humidities
                                      .map<double>((e) => e["value"].toDouble())
                                      .reduce((a, b) => a > b ? a : b);
                                  paddingH = (maxH - minH) * 0.1;
                                  if (paddingH < 1) paddingH = 1;
                                  minH -= paddingH;
                                  maxH += paddingH;
                                  final firstTimestampH = (humidities
                                          .first["timestamp"] as DateTime)
                                      .millisecondsSinceEpoch
                                      .toDouble();
                                  final lastTimestampH =
                                      (humidities.last["timestamp"] as DateTime)
                                          .millisecondsSinceEpoch
                                          .toDouble();
                                  intervalXH = (lastTimestampH >
                                          firstTimestampH)
                                      ? (lastTimestampH - firstTimestampH) / 7
                                      : 60000 * 15;
                                }

                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (temperatures.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 300,
                                          child: SfCartesianChart(
                                            title: ChartTitle(
                                                text:
                                                    'Kennel Temperature chart',
                                                textStyle: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface)),
                                            trackballBehavior:
                                                TrackballBehavior(
                                              enable: true,
                                              activationMode:
                                                  ActivationMode.singleTap,
                                              tooltipSettings:
                                                  InteractiveTooltip(
                                                      format: 'point.y %',
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer,
                                                      textStyle:
                                                          const TextStyle(
                                                              color:
                                                                  Colors.white),
                                                      canShowMarker: false),
                                              markerSettings:
                                                  TrackballMarkerSettings(
                                                      markerVisibility:
                                                          TrackballVisibilityMode
                                                              .visible,
                                                      height: 10,
                                                      width: 10,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer,
                                                      borderWidth: 0),
                                              lineType:
                                                  TrackballLineType.vertical,
                                              shouldAlwaysShow: false,
                                              // Specifica quali serie tracciare
                                              tooltipDisplayMode:
                                                  TrackballDisplayMode
                                                      .nearestPoint,
                                            ),
                                            zoomPanBehavior: ZoomPanBehavior(
                                              enablePanning: true,
                                              enablePinching: true,
                                              zoomMode: ZoomMode.x,
                                              enableDoubleTapZooming: true,
                                              enableSelectionZooming: true,
                                              enableMouseWheelZooming: true,
                                            ),
                                            plotAreaBorderColor: Colors.grey,
                                            primaryXAxis: NumericAxis(
                                              title: AxisTitle(
                                                  text: "Time",
                                                  textStyle: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface)),
                                              axisLine: const AxisLine(
                                                  width: 1, color: Colors.grey),
                                              desiredIntervals: 10,
                                              majorGridLines:
                                                  const MajorGridLines(
                                                      width: 1,
                                                      color: Colors.grey,
                                                      dashArray: [5, 5]),
                                              axisLabelFormatter:
                                                  (AxisLabelRenderDetails
                                                      details) {
                                                final dateTime = DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        details.value.toInt());
                                                return ChartAxisLabel(
                                                  '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
                                                  TextStyle(
                                                      fontSize: 10,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface),
                                                );
                                              },
                                              // Modifiche per avvicinare le label all'asse
                                              placeLabelsNearAxisLine: true,
                                              labelAlignment: LabelAlignment
                                                  .center, // Cambiato da end a center
                                              labelPosition: ChartDataLabelPosition
                                                  .outside, // Aggiunta questa proprietà/ Ridotto l'offset a 0
                                              labelRotation:
                                                  -45, // Rimossa la rotazione
                                              edgeLabelPlacement:
                                                  EdgeLabelPlacement.shift,
                                              initialVisibleMaximum:
                                                  DateTime.now()
                                                      .millisecondsSinceEpoch
                                                      .toDouble(),
                                              initialVisibleMinimum: DateTime
                                                          .now()
                                                      .millisecondsSinceEpoch
                                                      .toDouble() -
                                                  60 * 10 * 1000,
                                              interval: intervalX,
                                            ),
                                            primaryYAxis: NumericAxis(
                                              title: AxisTitle(
                                                  text: "Temperature (°C)",
                                                  textStyle: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface)),
                                              axisLine: const AxisLine(
                                                  width: 1, color: Colors.grey),
                                              majorGridLines:
                                                  const MajorGridLines(
                                                      width: 1,
                                                      color: Colors.grey,
                                                      dashArray: [5, 5]),
                                              minimum: minY,
                                              maximum: maxY,
                                              interval: 0.5,
                                              axisLabelFormatter:
                                                  (AxisLabelRenderDetails
                                                      details) {
                                                return ChartAxisLabel(
                                                  details.value.toString(),
                                                  TextStyle(
                                                      fontSize: 10,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface),
                                                );
                                              },
                                            ),
                                            series: <CartesianSeries>[
                                              // Prima serie: solo l'area con il gradiente
                                              SplineAreaSeries<Map, double>(
                                                dataSource: temperatures,
                                                xValueMapper: (e, _) =>
                                                    (e['timestamp'] as DateTime)
                                                        .millisecondsSinceEpoch
                                                        .toDouble(),
                                                yValueMapper: (e, _) =>
                                                    e['value'].toDouble(),
                                                borderColor: Colors.transparent,
                                                borderWidth: 0,
                                                enableTooltip: false,
                                                isVisibleInLegend: false,
                                                markerSettings:
                                                    const MarkerSettings(
                                                        isVisible: false),
                                                onCreateShader:
                                                    (ShaderDetails details) {
                                                  return ui.Gradient.linear(
                                                    Offset(details.rect.left,
                                                        details.rect.top),
                                                    Offset(details.rect.right,
                                                        details.rect.bottom),
                                                    [
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                          .withOpacity(0.7),
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .inversePrimary
                                                          .withOpacity(0.3),
                                                    ],
                                                    [0.0, 1.0],
                                                  );
                                                },
                                              ),
                                              // Seconda serie: solo la linea con il gradiente
                                              SplineSeries<Map, double>(
                                                dataSource: temperatures,
                                                xValueMapper: (e, _) =>
                                                    (e['timestamp'] as DateTime)
                                                        .millisecondsSinceEpoch
                                                        .toDouble(),
                                                yValueMapper: (e, _) =>
                                                    e['value'].toDouble(),
                                                width: 5,
                                                name: "Temperature",
                                                markerSettings: MarkerSettings(
                                                    isVisible: false,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer),
                                                enableTooltip: true,
                                                onCreateShader:
                                                    (ShaderDetails details) {
                                                  return ui.Gradient.linear(
                                                    Offset(details.rect.left,
                                                        details.rect.top),
                                                    Offset(details.rect.right,
                                                        details.rect.bottom),
                                                    [
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .inversePrimary,
                                                    ],
                                                    [0.0, 1.0],
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (humidities.isNotEmpty) ...[
                                        SizedBox(
                                          height: 300,
                                          child: SfCartesianChart(
                                            title: ChartTitle(
                                                text: 'Kennel Humidity chart',
                                                textStyle: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface)),
                                            trackballBehavior:
                                                TrackballBehavior(
                                              enable: true,
                                              activationMode:
                                                  ActivationMode.singleTap,
                                              tooltipSettings:
                                                  InteractiveTooltip(
                                                format: 'point.y %',
                                                canShowMarker: false,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .tertiaryContainer,
                                                textStyle: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                              markerSettings:
                                                  TrackballMarkerSettings(
                                                      markerVisibility:
                                                          TrackballVisibilityMode
                                                              .visible,
                                                      height: 10,
                                                      width: 10,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .tertiaryContainer,
                                                      borderWidth: 0),
                                              lineType:
                                                  TrackballLineType.vertical,
                                              shouldAlwaysShow: false,
                                              // Specifica quali serie tracciare
                                              tooltipDisplayMode:
                                                  TrackballDisplayMode
                                                      .nearestPoint,
                                            ),
                                            zoomPanBehavior: ZoomPanBehavior(
                                              enablePanning: true,
                                              enablePinching: true,
                                              zoomMode: ZoomMode.x,
                                              enableDoubleTapZooming: true,
                                              enableSelectionZooming: true,
                                              enableMouseWheelZooming: true,
                                              selectionRectColor:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .tertiaryContainer
                                                      .withOpacity(0.3),
                                              selectionRectBorderColor:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .tertiary,
                                              selectionRectBorderWidth: 1,
                                            ),
                                            plotAreaBorderColor: Colors.grey,
                                            primaryXAxis: NumericAxis(
                                              title: AxisTitle(
                                                  text: "Time",
                                                  textStyle: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface)),
                                              axisLine: const AxisLine(
                                                  width: 1, color: Colors.grey),
                                              desiredIntervals: 10,
                                              majorGridLines:
                                                  const MajorGridLines(
                                                      width: 1,
                                                      color: Colors.grey,
                                                      dashArray: [5, 5]),
                                              axisLabelFormatter:
                                                  (AxisLabelRenderDetails
                                                      details) {
                                                final dateTime = DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        details.value.toInt());
                                                return ChartAxisLabel(
                                                  '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
                                                  TextStyle(
                                                      fontSize: 10,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface),
                                                );
                                              },
                                              placeLabelsNearAxisLine: true,
                                              labelAlignment:
                                                  LabelAlignment.center,
                                              labelPosition:
                                                  ChartDataLabelPosition
                                                      .outside,
                                              labelRotation: -45,
                                              edgeLabelPlacement:
                                                  EdgeLabelPlacement.shift,
                                              initialVisibleMaximum:
                                                  DateTime.now()
                                                      .millisecondsSinceEpoch
                                                      .toDouble(),
                                              initialVisibleMinimum: DateTime
                                                          .now()
                                                      .millisecondsSinceEpoch
                                                      .toDouble() -
                                                  60 * 10 * 1000,
                                              interval: intervalXH,
                                            ),
                                            primaryYAxis: NumericAxis(
                                              title: AxisTitle(
                                                  text: "Humidity (%)",
                                                  textStyle: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface)),
                                              axisLine: const AxisLine(
                                                  width: 1, color: Colors.grey),
                                              majorGridLines:
                                                  const MajorGridLines(
                                                      width: 1,
                                                      color: Colors.grey,
                                                      dashArray: [5, 5]),
                                              minimum: minH,
                                              maximum: maxH,
                                              interval: 5,
                                              axisLabelFormatter:
                                                  (AxisLabelRenderDetails
                                                      details) {
                                                return ChartAxisLabel(
                                                  details.value.toString(),
                                                  TextStyle(
                                                      fontSize: 10,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface),
                                                );
                                              },
                                            ),
                                            series: <CartesianSeries>[
                                              // Prima serie: solo l'area con il gradiente
                                              SplineAreaSeries<Map, double>(
                                                dataSource: humidities,
                                                xValueMapper: (e, _) =>
                                                    (e['timestamp'] as DateTime)
                                                        .millisecondsSinceEpoch
                                                        .toDouble(),
                                                yValueMapper: (e, _) =>
                                                    e['value'].toDouble(),
                                                borderColor: Colors.transparent,
                                                borderWidth: 0,
                                                enableTooltip: false,
                                                isVisibleInLegend: false,
                                                markerSettings:
                                                    const MarkerSettings(
                                                        isVisible: false),
                                                onCreateShader:
                                                    (ShaderDetails details) {
                                                  return ui.Gradient.linear(
                                                    Offset(details.rect.left,
                                                        details.rect.top),
                                                    Offset(details.rect.right,
                                                        details.rect.bottom),
                                                    [
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .tertiary
                                                          .withOpacity(0.7),
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .tertiaryContainer
                                                          .withOpacity(0.3),
                                                    ],
                                                    [0.0, 1.0],
                                                  );
                                                },
                                              ),
                                              // Seconda serie: solo la linea con il gradiente
                                              SplineSeries<Map, double>(
                                                dataSource: humidities,
                                                xValueMapper: (e, _) =>
                                                    (e['timestamp'] as DateTime)
                                                        .millisecondsSinceEpoch
                                                        .toDouble(),
                                                yValueMapper: (e, _) =>
                                                    e['value'].toDouble(),
                                                width: 5,
                                                name: "Humidity",
                                                markerSettings: MarkerSettings(
                                                    isVisible: false,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .tertiaryContainer),
                                                enableTooltip: true,
                                                onCreateShader:
                                                    (ShaderDetails details) {
                                                  return ui.Gradient.linear(
                                                    Offset(details.rect.left,
                                                        details.rect.top),
                                                    Offset(details.rect.right,
                                                        details.rect.bottom),
                                                    [
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .tertiary,
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .tertiaryContainer,
                                                    ],
                                                    [0.0, 1.0],
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }
                              return Center(
                                  child: const CircularProgressIndicator());
                            }),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.red, width: 2),
                              borderRadius: BorderRadius.circular(10)),
                          child: HoldableButton(
                            loadingType: LoadingType.fillingLoading,
                            buttonColor: Theme.of(context).colorScheme.surface,
                            loadingColor: Colors.red,
                            duration: 5,
                            radius: 10,
                            beginFillingPoint: Alignment.centerLeft,
                            endFillingPoint: Alignment.centerRight,
                            resetAfterFinish: true,
                            onConfirm: () {
                              widget.onReservationCancel();
                              context.pop();
                            },
                            strokeWidth: 1,
                            hasVibrate: true,
                            width: MediaQuery.of(context).size.width,
                            height: 50,
                            child: const Text(
                              "HOLD TO CONFIRM TERMINATION",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      ]),
                ),
              ),
            ),
          ),
        ));
  }
}
