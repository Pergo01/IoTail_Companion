import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:rive/rive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:iotail_companion/UI/Material/login.dart';
import 'package:iotail_companion/UI/Material/splash_screen.dart';
import 'package:iotail_companion/UI/Material/navigation.dart';
import 'package:iotail_companion/theme/color_schemes.g.dart';
import 'package:iotail_companion/UI/Material/booking.dart';
import 'package:iotail_companion/UI/Material/dog_screen.dart';
import 'package:iotail_companion/UI/Material/user_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiveFile.initialize();
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );
  await FlutterSecureStorage(aOptions: _getAndroidOptions())
      .write(key: "ip", value: "localhost");
  runApp(const MyApp());
}

final materialRouter = GoRouter(initialLocation: "/", routes: [
  GoRoute(
      name: "Login",
      path: "/Login",
      builder: (build, context) {
        String ip = context.extra as String;
        return LoginWithRive(
          ip: ip,
        );
      }),
  GoRoute(
      name: "SplashScreen",
      path: "/",
      builder: (build, context) => const SplashScreen()),
  GoRoute(
      name: "Navigation",
      path: "/Navigation",
      builder: (build, context) {
        Map extra = context.extra as Map;
        return Navigation(
            ip: extra["ip"], token: extra["token"], userID: extra["userID"]);
      }),
  GoRoute(
      name: "Booking",
      path: "/Booking",
      builder: (build, context) {
        final MqttServerClient client = context.extra as MqttServerClient;
        return Booking(
          client: client,
        );
      }),
  GoRoute(
      name: "UserScreen",
      path: "/User",
      builder: (build, context) {
        Map extra = context.extra as Map;
        return UserScreen(
          user: extra["user"],
          ip: extra["ip"],
          token: extra["token"],
          onEdit: extra["onEdit"],
        );
      }),
  GoRoute(
      name: "DogScreen",
      path: "/Dog",
      builder: (build, context) {
        Map extra = context.extra as Map;
        return DogScreen(
          dog: extra["dog"],
          userID: extra["userID"],
          ip: extra["ip"],
          token: extra["token"],
          onEdit: extra["onEdit"],
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
