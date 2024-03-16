import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

class Booking extends StatefulWidget {
  final MqttServerClient client;
  const Booking({Key? key, required this.client}) : super(key: key);

  @override
  _BookingState createState() => _BookingState();
}

class _BookingState extends State<Booking> {
  late StreamSubscription<List<MqttReceivedMessage<MqttMessage>>> _subscription;
  String latestUpdate = '';

  @override
  void initState() {
    super.initState();
    _subscribeToTopic();
  }

  @override
  void dispose() {
    _unsubscribeFromTopic();
    super.dispose();
  }

  void _subscribeToTopic() {
    _subscription = widget.client.updates
        .listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final MqttPublishMessage message =
          messages[0].payload as MqttPublishMessage;
      final String payload =
          MqttUtilities.bytesToStringAsString(message.payload.message!);
      final Map<String, dynamic> json = jsonDecode(payload);
      if (json.containsKey('message')) {
        setState(() {
          latestUpdate = json['message'];
        });
      }
    });
    widget.client.subscribe('IoT_sample', MqttQos.exactlyOnce);
  }

  void _unsubscribeFromTopic() {
    _subscription.cancel();
    widget.client.unsubscribeStringTopic('IoT_sample');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("IoTail"),
      ),
      body: Center(
        child: latestUpdate.isNotEmpty
            ? Text('Messaggio MQTT: $latestUpdate')
            : const CircularProgressIndicator(),
      ),
    );
  }
}
