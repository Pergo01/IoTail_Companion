import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holdable_button/holdable_button.dart';
import 'package:holdable_button/utils/utils.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
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

  @override
  void initState() {
    super.initState();
    tempHumid = getTemperatureHumidity();
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
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SingleChildScrollView(
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
                                    color:
                                        Theme.of(context).colorScheme.surface,
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
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
                                              child:
                                                  CircularProgressIndicator());
                                        },
                                      )
                                    : Container(),
                              ),
                              if (!showCamera)
                                ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.all(
                                                Theme.of(context)
                                                    .colorScheme
                                                    .primary),
                                        foregroundColor:
                                            WidgetStateProperty.all(
                                                Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary)),
                                    onPressed: () async {
                                      final builder = MqttPayloadBuilder();
                                      builder.addString(
                                          jsonEncode({"message": "on"}));
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
                                          Text(
                                              "Humidity: ${snapshot.data![1]}%",
                                              style: TextStyle(fontSize: 20)),
                                        ]);
                                  }
                                  if (snapshot.hasError) {
                                    return Text("Error: ${snapshot.error}");
                                  }
                                  return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Temperature: ...°C",
                                            style: TextStyle(fontSize: 20)),
                                        Text("Humidity: ...%",
                                            style: TextStyle(fontSize: 20)),
                                      ]);
                                }),
                          ]),
                    ),
                  ),
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
                ],
              ),
            ),
          ),
        ));
  }
}
