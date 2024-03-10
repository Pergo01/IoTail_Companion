import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iotail_companion/UI/Material/home.dart';

import 'UI/Material/login.dart';

void main() {
  runApp(const MyApp());
}

final materialRouter = GoRouter(initialLocation: "/", routes: [
  GoRoute(name: "Login", path: "/", builder: (build, context) => Login()),
  GoRoute(
      name: "Home", path: "/Home", builder: (context, state) => const Home())
]);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IoTail',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.lightBlue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      routerConfig: materialRouter,
    );
  }
}
