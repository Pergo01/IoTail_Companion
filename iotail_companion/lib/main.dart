import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iotail_companion/UI/Material/booking.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

import 'UI/Material/login.dart';
import 'UI/Material/navigation.dart';
import 'theme/color_schemes.g.dart';

void main() {
  final client = MqttServerClient("mqtt.eclipseprojects.io", "");
  client.connect('IoTail_client');
  runApp(MyApp(client: client));
}

final materialRouter = GoRouter(initialLocation: "/Navigation", routes: [
  GoRoute(name: "Login", path: "/", builder: (build, context) => const Login()),
  //GoRoute(
  //name: "Home", path: "/Home", builder: (context, state) => const Home()),
  //GoRoute(name: "Map", path: "/Map", builder: (context, state) => const Map()),
  GoRoute(
      name: "Navigation",
      path: "/Navigation",
      builder: (build, context) => const Navigation()),
  GoRoute(
      name: "Booking",
      path: "/Booking",
      builder: (build, context) => const Booking())
]);

class MyApp extends StatelessWidget {
  final MqttServerClient client;
  const MyApp({super.key, required this.client});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IoTail',
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
      ),
      routerConfig: materialRouter,
    );
  }
}
