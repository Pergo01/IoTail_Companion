import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () => context.push("/Booking", extra: widget.client),
                child: const Text("Vai a Booking"))
          ],
        ),
      ),
    );
  }
}
