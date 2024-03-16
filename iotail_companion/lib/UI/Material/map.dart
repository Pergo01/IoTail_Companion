import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

class Map extends StatefulWidget {
  final MqttServerClient client;
  const Map({Key? key, required this.client});

  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> with TickerProviderStateMixin {
  static const Duration duration = Duration(milliseconds: 300);
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: duration,
      vsync: this,
    );
    controller.forward();
  }

  @override
  void dispose() {
    controller.reverse();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: controller.drive(
        Tween<Offset>(
          begin: const Offset(1, 0), // Out of view on the right.
          end: Offset.zero,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () =>
                      context.push("/Booking", extra: widget.client),
                  child: const Text("Vai a Booking"))
            ],
          ),
        ),
      ),
    );
  }
}
