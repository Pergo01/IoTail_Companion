import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holdable_button/holdable_button.dart';
import 'package:holdable_button/utils/utils.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:slide_countdown/slide_countdown.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    as secure_storage;

import 'package:iotail_companion/util/reservation.dart';
import 'package:iotail_companion/util/dog.dart';
import 'package:iotail_companion/util/requests.dart' as requests;

final reservationDetailsKey =
    GlobalKey(); // Key for the reservation details section
final cameraBoxKey = GlobalKey(); // Key for the camera box section
final currentMeasurementsKey =
    GlobalKey(); // Key for the current measurements section
final plotsKey = GlobalKey(); // Key for the plots section
final reservationCancelButtonKey =
    GlobalKey(); // Key for the reservation cancel button

class ReservationScreen extends StatefulWidget {
  final Reservation
      reservation; // Reservation object containing details about the reservation
  final Dog dog; // Dog object containing details about the dog
  final String ip; // IP address of the kennel system
  final String token; // Token for authentication with the kennel system
  final MqttServerClient
      client; // MQTT client for communication with the kennel system
  final VoidCallback
      onReservationCancel; // Callback function to be called when the reservation is canceled

  const ReservationScreen(
      {super.key,
      required this.reservation,
      required this.dog,
      required this.ip,
      required this.token,
      required this.client,
      required this.onReservationCancel});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  bool showCamera = false; // Flag to control the visibility of the camera box
  InAppWebViewController?
      webController; // Controller for the InAppWebView to manage the camera feed
  late Future<bool> isCameraReady; // Future to check if the camera is ready
  late Future<List<double>>
      tempHumid; // Future to fetch temperature and humidity data from the kennel sensors
  late Future<Map>
      kennelMeasurements; // Future to fetch kennel measurements data
  ScrollController scrollController =
      ScrollController(); // Controller for the scroll view to manage scrolling behavior

  late secure_storage.FlutterSecureStorage
      storage; // Declaring secure storage variable for persistently storing data or writing precedently stored data. This allows to persist information after the app is closed.
  secure_storage.AndroidOptions _getAndroidOptions() =>
      const secure_storage.AndroidOptions(
        encryptedSharedPreferences: true,
      ); // Options for Android to use encrypted shared preferences for secure storage.

  /// Shows the coach mark for the items in the screen after the widget is built.
  void _showCoachMark() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensures the coach mark is shown after the widget is built.
      storage.read(key: "reservationTutorialComplete").then((value) {
        // Reads the tutorial completion status from secure storage.
        if (value != 'completed') {
          ShowCaseWidget.of(context).startShowCase([
            reservationDetailsKey,
            cameraBoxKey,
            currentMeasurementsKey,
            plotsKey,
            reservationCancelButtonKey,
          ]); // Starts the showcase if it is the first time the user is accessing this screen.
        }
      });
    });
  }

  /// Waits for the camera to be ready by reloading the web view after a delay. (Arbitrary delay of 4 seconds)
  Future<bool> waitForCamera() async {
    bool camera = false;
    await Future.delayed(Duration(seconds: 4), () {
      webController?.reload();
    }).then((val) => camera = true);
    return camera;
  }

  /// Fetches the temperature and humidity data from the kennel sensors.
  Future<List<double>> getTemperatureHumidity() async {
    List<double> tmp = await requests.getTemperatureHumidity(widget.ip);
    return tmp;
  }

  /// Fetches the kennel measurements data from thingspeak.
  Future<Map> getKennelMeasurements() async {
    Map data = await requests.getKennelmeasurements(widget.ip, widget.token,
        widget.reservation.kennelID, widget.reservation.activationTime!);
    return data;
  }

  @override
  void initState() {
    super.initState();
    storage = secure_storage.FlutterSecureStorage(
        aOptions:
            _getAndroidOptions()); // Initializing secure storage with Android options for encrypted shared preferences.
    tempHumid =
        getTemperatureHumidity(); // Fetching temperature and humidity data from the kennel sensors.
    kennelMeasurements =
        getKennelMeasurements(); // Fetching kennel measurements data from thingspeak.
    _showCoachMark(); // Showing the coach mark after the widget is built if the user has not completed the tutorial.
  }

  @override
  Widget build(BuildContext context) {
    DateTime startTime = DateTime.fromMillisecondsSinceEpoch(widget
            .reservation.activationTime! *
        1000); // Converting the activation time from milliseconds since epoch to DateTime.
    Duration remainingTime = DateTime.now().difference(
        startTime); // Calculating the remaining time since the activation time.
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
            ).createShader(
                bounds), // Gradient for the title text from top left to bottom right
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
                if (webController != null && showCamera) {
                  await webController!
                      .reload(); // Reload the web view to refresh the camera feed
                }
                setState(() {
                  tempHumid =
                      getTemperatureHumidity(); // Refresh temperature and humidity data
                  kennelMeasurements =
                      getKennelMeasurements(); // Refresh kennel measurements data
                });
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                controller: scrollController,
                child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Showcase(
                          key: reservationDetailsKey,
                          titleAlignment: Alignment.centerLeft,
                          title: "Reservation Details",
                          titleTextStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          descriptionAlignment: Alignment.centerLeft,
                          description:
                              "In this section, you can see the details of your reservation.",
                          descTextStyle: Theme.of(context).textTheme.bodyMedium,
                          tooltipBackgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          targetPadding: EdgeInsets.symmetric(horizontal: 4),
                          targetBorderRadius: BorderRadius.circular(10),
                          tooltipActions: [
                            // Next button
                            TooltipActionButton(
                              type: TooltipDefaultActionType.next,
                              name: "Next",
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            )
                          ],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Dog name
                              Text(
                                "Dog: ${widget.dog.name}",
                                style: TextStyle(fontSize: 40),
                              ),
                              // Kennel ID
                              Text(
                                "Kennel: ${widget.reservation.kennelID}",
                                style: TextStyle(fontSize: 30),
                              ),
                              // Activation time
                              Text(
                                "Activated at: ${DateTime.fromMillisecondsSinceEpoch(widget.reservation.activationTime! * 1000, isUtc: false).hour.toString().padLeft(2, '0')}:${DateTime.fromMillisecondsSinceEpoch(widget.reservation.activationTime! * 1000, isUtc: false).minute.toString().padLeft(2, '0')}",
                                style: TextStyle(fontSize: 20),
                              ),
                              // Time lasted since activation
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
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                    ),
                                    style: const TextStyle(fontSize: 20),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        Showcase(
                          key: cameraBoxKey,
                          titleAlignment: Alignment.centerLeft,
                          title: "Camera box",
                          titleTextStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          descriptionAlignment: Alignment.centerLeft,
                          description:
                              "In this box, you can see the live camera feed from the kennel. Activate it by pressing the button below and close it by pressing the close button in the top right corner.",
                          descTextStyle: Theme.of(context).textTheme.bodyMedium,
                          tooltipBackgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          targetBorderRadius: BorderRadius.circular(8),
                          tooltipActions: [
                            // Previous button
                            TooltipActionButton(
                                type: TooltipDefaultActionType.previous,
                                leadIcon: ActionButtonIcon(
                                  icon: Icon(
                                    Icons.arrow_back_ios,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ), // Icon
                                ), // ActionButtonIcon
                                name: "Previous",
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                onTap: () {
                                  // Scroll to the reservation details section
                                  Scrollable.ensureVisible(
                                    reservationDetailsKey.currentContext!,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  ).then((_) {
                                    // Wait until the scroll is complete
                                    ShowCaseWidget.of(context)
                                        .previous(); // Go to the next showcase item
                                  });
                                }),

                            // Next button
                            TooltipActionButton(
                              type: TooltipDefaultActionType.next,
                              name: "Next",
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            )
                          ],
                          child: Stack(alignment: Alignment.center, children: [
                            Container(
                                height: 200,
                                width: MediaQuery.of(context).size.width,
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8)),
                                child: showCamera
                                    ? FutureBuilder(
                                        future: isCameraReady,
                                        builder: (BuildContext context,
                                            AsyncSnapshot<bool> snapshot) {
                                          if (snapshot.hasData) {
                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: InAppWebView(
                                                initialUrlRequest: URLRequest(
                                                  url: WebUri(
                                                      'http://${widget.ip}:8090/camera_0'),
                                                ),
                                                initialSettings:
                                                    InAppWebViewSettings(),
                                                onWebViewCreated: (controller) {
                                                  webController = controller;
                                                },
                                                onLoadStop: (controller, url) {
                                                  controller.evaluateJavascript(
                                                      source: '''
                                                      document.querySelector('meta[name="viewport"]').setAttribute('content',
                                                      'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
                                                      document.body.style.overflow = 'hidden';
                                                      document.documentElement.style.overflow = 'hidden';
                                                      document.body.style.margin = '0';
                                                      document.body.style.padding = '0';
                                                    ''');
                                                  setState(() {
                                                    showCamera =
                                                        true; // Set showCamera to true when the web view is loaded
                                                  });
                                                },
                                              ),
                                            ); // Display the InAppWebView with the camera feed
                                          }
                                          return Center(
                                              child:
                                                  CircularProgressIndicator()); // Show a loading indicator while waiting for the camera to be ready
                                        },
                                      )
                                    : Container()), // Empty container when the camera is not shown
                            if (!showCamera) // If the camera is not shown, display the button
                              ElevatedButton(
                                  style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                          Theme.of(context)
                                              .colorScheme
                                              .primary),
                                      foregroundColor: WidgetStateProperty.all(
                                          Theme.of(context)
                                              .colorScheme
                                              .onPrimary)),
                                  onPressed: () async {
                                    final builder =
                                        MqttPayloadBuilder(); // Create a new MqttPayloadBuilder to build the payload for the MQTT message
                                    builder.addString(jsonEncode({
                                      "message": "on"
                                    })); // Add the payload to the builder
                                    widget.client.publishMessage(
                                        "IoTail/kennel1/camera", // should be the correct topic for your camera, "IoTail/kennel${widget.reservation.kennelID}/camera"
                                        MqttQos.exactlyOnce,
                                        builder
                                            .payload!); // Publish the MQTT message to turn on the camera
                                    if (!showCamera) {
                                      // If the camera is not shown, toggle the showCamera state and wait for the camera to be ready
                                      setState(() {
                                        showCamera =
                                            !showCamera; // Toggle the showCamera state
                                      });
                                      isCameraReady =
                                          waitForCamera(); // Wait for the camera to be ready
                                    } else {
                                      setState(() {
                                        showCamera =
                                            !showCamera; // Toggle the showCamera state
                                      });
                                    }
                                  },
                                  child: const Text("Show camera")),
                            if (showCamera) // If the camera is shown, display the close button
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        showCamera =
                                            !showCamera; // Toggle the showCamera state to hide the camera
                                      });
                                      final builder =
                                          MqttPayloadBuilder(); // Create a new MqttPayloadBuilder to build the payload for the MQTT message
                                      builder.addString(jsonEncode({
                                        "message": "off"
                                      })); // Add the payload to the builder
                                      widget.client.publishMessage(
                                          "IoTail/kennel1/camera",
                                          MqttQos.exactlyOnce,
                                          builder
                                              .payload!); // Publish the MQTT message to turn off the camera
                                    },
                                    icon: Icon(Icons.close)),
                              )
                          ]),
                        ),
                        Divider(
                          thickness: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ), // Divider to separate the camera box from the current measurements section
                        Showcase(
                          key: currentMeasurementsKey,
                          titleAlignment: Alignment.centerLeft,
                          title: "Current Measurements",
                          titleTextStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          descriptionAlignment: Alignment.centerLeft,
                          description:
                              "In this section, you can see the current temperature and humidity measurements from the kennel's sensors.",
                          descTextStyle: Theme.of(context).textTheme.bodyMedium,
                          targetPadding: EdgeInsets.all(4),
                          targetBorderRadius: BorderRadius.circular(10),
                          disposeOnTap: false,
                          onTargetClick: () {
                            // When the target is clicked, scroll to the plots section
                            Scrollable.ensureVisible(
                              plotsKey.currentContext!,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            ).then((_) {
                              // Wait until the scroll is complete
                              ShowCaseWidget.of(context)
                                  .next(); // Go to the next showcase item
                            });
                          },
                          tooltipBackgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          tooltipActions: [
                            // Previous button
                            TooltipActionButton(
                                type: TooltipDefaultActionType.previous,
                                leadIcon: ActionButtonIcon(
                                  icon: Icon(
                                    Icons.arrow_back_ios,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ), // Icon
                                ), // ActionButtonIcon
                                name: "Previous",
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                onTap: () {
                                  // Scroll to the camera box section
                                  Scrollable.ensureVisible(
                                    cameraBoxKey.currentContext!,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  ).then((_) {
                                    // Wait until the scroll is complete
                                    ShowCaseWidget.of(context)
                                        .previous(); // Go to the previous showcase item
                                  });
                                }),

                            // Next button
                            TooltipActionButton(
                                type: TooltipDefaultActionType.next,
                                name: "Next",
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                onTap: () {
                                  // Scroll to the plots section
                                  Scrollable.ensureVisible(
                                    plotsKey.currentContext!,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  ).then((_) {
                                    // Wait until the scroll is complete
                                    ShowCaseWidget.of(context)
                                        .next(); // Go to the next showcase item
                                  });
                                }),
                          ],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Current environment measurements:",
                                style: TextStyle(fontSize: 25),
                              ),
                              FutureBuilder(
                                  future: tempHumid,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      // If the data is available, display the temperature and humidity
                                      return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                "Temperature: ${snapshot.data![0]}°C",
                                                style: TextStyle(fontSize: 20)),
                                            Text(
                                                "Humidity: ${snapshot.data![1]}%",
                                                style: TextStyle(fontSize: 20)),
                                          ]);
                                    }
                                    if (snapshot.hasError) {
                                      // If there is an error fetching the data, display an error message
                                      return Text(
                                          "Error: Unable to fetch data from sensors");
                                    }
                                    return Column(
                                        // While the data is being fetched, display a loading indicator
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("Temperature: ...°C",
                                              style: TextStyle(fontSize: 20)),
                                          Text("Humidity: ...%",
                                              style: TextStyle(fontSize: 20)),
                                        ]);
                                  }),
                            ],
                          ),
                        ),
                        Divider(
                          thickness: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ), // Divider to separate the current measurements section from the plots section
                        FutureBuilder(
                            future: kennelMeasurements,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                // If there is an error fetching the kennel measurements, display an error message
                                return Text("Error: ${snapshot.error}");
                              }
                              if (snapshot.hasData) {
                                // If the data is available, display the plots
                                // Find min and max values for Y axis for temperature and humidity
                                final List<
                                    Map> temperatures = List<Map>.from(snapshot
                                        .data![
                                    "temperature"]); // Fetching temperature data from the snapshot
                                final List<
                                    Map> humidities = List<Map>.from(snapshot
                                        .data![
                                    "humidity"]); // Fetching humidity data from the snapshot

                                if (temperatures.isEmpty &&
                                    humidities.isEmpty) {
                                  // If both temperature and humidity data are empty, display a message indicating no data is available
                                  return const Center(
                                      child: Text(
                                    "No measurements available for this kennel.",
                                  ));
                                }

                                // Initialize variables for min and max values for Y axis, padding, and intervals
                                double minY = 0,
                                    maxY = 0,
                                    minH = 0,
                                    maxH = 0,
                                    paddingY = 1,
                                    paddingH = 1;
                                double intervalX = 60000 *
                                        15, // 15 minutes in milliseconds
                                    intervalXH = 60000 *
                                        15; // 15 minutes in milliseconds (for humidity)

                                if (temperatures.isNotEmpty) {
                                  // If there are temperature measurements
                                  minY = temperatures
                                      .map<double>((e) => e["value"].toDouble())
                                      .reduce((a, b) => a < b
                                          ? a
                                          : b); // Find the minimum temperature value
                                  maxY = temperatures
                                      .map<double>((e) => e["value"].toDouble())
                                      .reduce((a, b) => a > b
                                          ? a
                                          : b); // Find the maximum temperature value
                                  paddingY = (maxY - minY) *
                                      0.1; // Calculate padding for the Y axis
                                  if (paddingY < 1) {
                                    paddingY =
                                        0.5; // Ensure padding is at least 0.5
                                  }
                                  minY -=
                                      paddingY; // Adjust the minimum value by subtracting padding
                                  maxY +=
                                      paddingY; // Adjust the maximum value by adding padding
                                  final firstTimestamp = temperatures
                                      .first["timestamp"]
                                      .toDouble(); // Get the first timestamp
                                  final lastTimestamp = temperatures
                                      .last["timestamp"]
                                      .toDouble(); // Get the last timestamp
                                  intervalX = (lastTimestamp > firstTimestamp)
                                      ? (lastTimestamp - firstTimestamp) / 7
                                      : 60000 *
                                          15; // Calculate the interval for the X axis based on the timestamps (default to 15 minutes)
                                }

                                if (humidities.isNotEmpty) {
                                  // If there are humidity measurements
                                  minH = humidities
                                      .map<double>((e) => e["value"].toDouble())
                                      .reduce((a, b) => a < b
                                          ? a
                                          : b); // Find the minimum humidity value
                                  maxH = humidities
                                      .map<double>((e) => e["value"].toDouble())
                                      .reduce((a, b) => a > b
                                          ? a
                                          : b); // Find the maximum humidity value
                                  paddingH = (maxH - minH) *
                                      0.1; // Calculate padding for the Y axis
                                  if (paddingH < 1) {
                                    paddingH =
                                        1; // Ensure padding is at least 1
                                  }
                                  minH -=
                                      paddingH; // Adjust the minimum value by subtracting padding
                                  maxH +=
                                      paddingH; // Adjust the maximum value by adding padding
                                  final firstTimestampH = humidities
                                      .first["timestamp"]
                                      .toDouble(); // Get the first timestamp
                                  final lastTimestampH = humidities
                                      .last["timestamp"]
                                      .toDouble(); // Get the last timestamp
                                  intervalXH = (lastTimestampH >
                                          firstTimestampH)
                                      ? (lastTimestampH - firstTimestampH) / 7
                                      : 60000 *
                                          15; // Calculate the interval for the X axis based on the timestamps (default to 15 minutes)
                                }

                                return Showcase(
                                  key: plotsKey,
                                  titleAlignment: Alignment.centerLeft,
                                  title: "Plots",
                                  titleTextStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  descriptionAlignment: Alignment.centerLeft,
                                  description:
                                      "In this section, you can see the temperature and humidity plots of the kennel. Plots are zoomable and pannable, and you can tap on the points to see the exact values and long tap + drag to select a range to zoom.",
                                  descTextStyle:
                                      Theme.of(context).textTheme.bodyMedium,
                                  tooltipBackgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  targetBorderRadius: BorderRadius.circular(20),
                                  tooltipActions: [
                                    // Previous button
                                    TooltipActionButton(
                                        type: TooltipDefaultActionType.previous,
                                        leadIcon: ActionButtonIcon(
                                          icon: Icon(
                                            Icons.arrow_back_ios,
                                            size: 16,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                          ), // Icon
                                        ), // ActionButtonIcon
                                        name: "Previous",
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary),
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        onTap: () {
                                          // Scroll to the current measurements section
                                          Scrollable.ensureVisible(
                                            currentMeasurementsKey
                                                .currentContext!,
                                            duration: const Duration(
                                                milliseconds: 400),
                                            curve: Curves.easeInOut,
                                          ).then((_) {
                                            // Wait until the scroll is complete
                                            ShowCaseWidget.of(context)
                                                .previous(); // Go to the next showcase item
                                          });
                                        }),

                                    // Next button
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.next,
                                      name: "Next",
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer),
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                    )
                                  ],
                                  child: Padding(
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                        color:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primaryContainer,
                                                        textStyle:
                                                            const TextStyle(
                                                                color: Colors
                                                                    .white),
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
                                                    width: 1,
                                                    color: Colors.grey),
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
                                                          details.value
                                                              .toInt());
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
                                                    width: 1,
                                                    color: Colors.grey),
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
                                                // First series: only the area with the gradient
                                                SplineAreaSeries<Map, double>(
                                                  dataSource: temperatures,
                                                  xValueMapper: (e, _) =>
                                                      e['timestamp'].toDouble(),
                                                  yValueMapper: (e, _) =>
                                                      e['value'].toDouble(),
                                                  borderColor:
                                                      Colors.transparent,
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
                                                // Second series: only the line with the gradient
                                                SplineSeries<Map, double>(
                                                  dataSource: temperatures,
                                                  xValueMapper: (e, _) =>
                                                      e['timestamp'].toDouble(),
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                    width: 1,
                                                    color: Colors.grey),
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
                                                          details.value
                                                              .toInt());
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
                                                    width: 1,
                                                    color: Colors.grey),
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
                                                // First series: only the area with the gradient
                                                SplineAreaSeries<Map, double>(
                                                  dataSource: humidities,
                                                  xValueMapper: (e, _) =>
                                                      e['timestamp'].toDouble(),
                                                  yValueMapper: (e, _) =>
                                                      e['value'].toDouble(),
                                                  borderColor:
                                                      Colors.transparent,
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
                                                // Second series: only the line with the gradient
                                                SplineSeries<Map, double>(
                                                  dataSource: humidities,
                                                  xValueMapper: (e, _) =>
                                                      e['timestamp'].toDouble(),
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
                                  ),
                                );
                              }
                              return Center(
                                  child: const CircularProgressIndicator());
                            }),
                        Showcase(
                          key: reservationCancelButtonKey,
                          titleAlignment: Alignment.centerLeft,
                          title: "Terminate Occupation",
                          titleTextStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          descriptionAlignment: Alignment.centerLeft,
                          description:
                              "From here you can terminate the occupation of the kennel.",
                          descTextStyle: Theme.of(context).textTheme.bodyMedium,
                          tooltipBackgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          targetPadding: EdgeInsets.symmetric(horizontal: 8),
                          targetBorderRadius: BorderRadius.circular(20),
                          tooltipActions: [
                            TooltipActionButton(
                                type: TooltipDefaultActionType.previous,
                                leadIcon: ActionButtonIcon(
                                  icon: Icon(
                                    Icons.arrow_back_ios,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ), // Icon
                                ), // ActionButtonIcon
                                name: "Previous",
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                onTap: () {
                                  // Scroll to the plots section
                                  Scrollable.ensureVisible(
                                    plotsKey.currentContext!,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  ).then((_) {
                                    // Go to the previous showcase item
                                    ShowCaseWidget.of(context)
                                        .previous(); // Go to the next showcase item
                                  });
                                }),

                            // Next button
                            TooltipActionButton(
                                type: TooltipDefaultActionType.next,
                                name: "Finish",
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                onTap: () {
                                  storage.write(
                                      key: "reservationTutorialComplete",
                                      value:
                                          "completed"); // Mark the reservation tutorial as completed
                                  ShowCaseWidget.of(context)
                                      .next(); // Go to the next showcase item
                                })
                          ],
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.red, width: 2),
                                borderRadius: BorderRadius.circular(12)),
                            child: HoldableButton(
                              loadingType: LoadingType.fillingLoading,
                              buttonColor:
                                  Theme.of(context).colorScheme.surface,
                              loadingColor: Colors.red,
                              duration: 5,
                              radius: 10,
                              beginFillingPoint: Alignment.centerLeft,
                              endFillingPoint: Alignment.centerRight,
                              resetAfterFinish: true,
                              onConfirm: () {
                                widget
                                    .onReservationCancel(); // Call the callback to cancel the reservation
                                context.pop(); // Close the screen
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
