import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iotail_companion/UI/Material/booking.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

import 'UI/Material/login.dart';
import 'UI/Material/navigation.dart';
import 'theme/color_schemes.g.dart';

void main() {
  runApp(const MyApp());
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
      builder: (build, context) {
        final MqttServerClient client = context.extra as MqttServerClient;
        return Booking(
          client: client,
        );
      })
]);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
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
