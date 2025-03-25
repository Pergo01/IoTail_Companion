import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

import 'package:iotail_companion/util/reservation.dart';

class ReservationScreen extends StatefulWidget {
  final Reservation reservation;
  final String ip;
  final MqttServerClient client;

  const ReservationScreen(
      {super.key,
      required this.reservation,
      required this.ip,
      required this.client});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  bool showCamera = false;
  late final WebViewController webController;

  @override
  void initState() {
    super.initState();
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
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: RefreshIndicator(
            onRefresh: () async {
              webController.reload();
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextButton(
                          onPressed: () {
                            final builder = MqttPayloadBuilder();
                            builder.addString(jsonEncode(
                                {"message": !showCamera ? "on" : "off"}));
                            widget.client.publishMessage(
                                "IoTail/kennel1/camera",
                                MqttQos.exactlyOnce,
                                builder.payload!);
                            if (!showCamera) {
                              Future.delayed(Duration(seconds: 4), () {
                                webController.reload();
                                webController.enableZoom(false);
                                setState(() {
                                  showCamera = !showCamera;
                                });
                              });
                            } else {
                              setState(() {
                                showCamera = !showCamera;
                              });
                            }
                          },
                          child:
                              Text(showCamera ? "Hide camera" : "Show camera")),
                      Container(
                        height: 200,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8)),
                        // Set a fixed height for the WebView
                        child: showCamera
                            ? WebViewWidget(
                                controller: webController,
                              )
                            : Container(),
                      ),
                    ]),
              ),
            ),
          ),
        ));
  }
}
