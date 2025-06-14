import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:iotail_companion/firebase_options.dart';
import 'package:iotail_companion/UI/Material/login.dart';
import 'package:iotail_companion/UI/Material/splash_screen.dart';
import 'package:iotail_companion/UI/Material/navigation.dart';
import 'package:iotail_companion/theme/color_schemes.g.dart';
import 'package:iotail_companion/UI/Material/dog_screen.dart';
import 'package:iotail_companion/UI/Material/user_screen.dart';
import 'package:iotail_companion/util/firebase_api.dart';
import 'package:iotail_companion/UI/Material/reservation_screen.dart';
import 'package:iotail_companion/util/tutorial_keys.dart';
import 'package:iotail_companion/util/tutorial_manager.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter bindings are initialized
  await RiveFile.initialize(); // Initialize Rive for animations in Login screen
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase with the default options for the current platform
  await FirebaseApi.instance.initialize(); // Initialize Firebase API
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      ); // Define Android options for secure storage
  await FlutterSecureStorage(
          aOptions:
              _getAndroidOptions()) // Initialize Flutter Secure Storage with Android options
      .write(
          key: "ip",
          value:
              "192.168.0.243"); // Write a default IP address to secure storage. THIS IS THE IP OF THE SERVER (RASPBERRY PI), CHANGE IT TO YOURS. Use 10.0.2.2 if you are using an android emulator and the server is running on the same machine or localhost for the iOS emulator.
  runApp(const MyApp());
}

// This is the main router configuration for the application using GoRouter
final materialRouter = GoRouter(initialLocation: "/", routes: [
  GoRoute(
      name: "Login",
      path: "/Login",
      builder: (build, context) {
        String ip = context.extra as String;
        return LoginWithRive(
          ip: ip,
        );
      }), // Route for the login screen
  GoRoute(
      name: "SplashScreen",
      path: "/",
      builder: (build, context) =>
          const SplashScreen()), // Route for the splash screen
  GoRoute(
      name: "Navigation",
      path: "/Navigation",
      builder: (build, context) {
        Map extra = context.extra as Map;
        return Navigation(
            ip: extra["ip"], token: extra["token"], userID: extra["userID"]);
      }), // Route for the main navigation screen
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
      }), // Route for the user profile screen
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
          breeds: extra["breeds"],
          onEdit: extra["onEdit"],
        );
      }), // Route for the dog profile screen
  GoRoute(
      name: "ReservationScreen",
      path: "/ReservationScreen",
      builder: (build, context) {
        Map extra = context.extra as Map;
        return ReservationScreen(
          reservation: extra["reservation"],
          dog: extra["dog"],
          ip: extra["ip"],
          client: extra["client"], // Pass the client
          onReservationCancel: extra["onReservationCancel"],
        );
      }), // Route for the reservation screen
]);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]); // Lock the app to portrait mode
    final isDarkTheme = MediaQuery.of(context).platformBrightness ==
        Brightness.dark; // Check if the current theme is dark

    // Wrap the app with ShowCaseWidget to enable tutorial features
    return ShowCaseWidget(
      builder: (context) => MaterialApp.router(
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
      ), // This is the main MaterialApp configuration, with themes and router for the different screens

      // This is the configuration for the "Skip" button in the tutorial
      globalFloatingActionWidget: (showcaseContext) {
        return FloatingActionWidget(
          bottom: 0,
          left: 24,
          child: TextButton(
              onPressed: () async {
                // Completely stops all the tutorials and marks them as completed
                ShowCaseWidget.of(showcaseContext)
                    .dismiss(); // Dismiss the showcase
                TutorialManager
                    .markDogTutorialCompleted(); // Mark the dog tutorial as completed
                TutorialManager
                    .markDogTutorialCompleted(); // Mark the user tutorial as completed
                TutorialManager
                    .markReservationTutorialCompleted(); // Mark the reservation tutorial as completed
                final storage = FlutterSecureStorage(
                    aOptions: const AndroidOptions(
                  encryptedSharedPreferences: true,
                )); // Initialize secure storage with Android options
                storage.write(
                    key: "userEditTutorialComplete",
                    value:
                        "completed"); // Write the user edit tutorial completion status
                storage.write(
                    key: "dogEditTutorialComplete",
                    value:
                        "completed"); // Write the dog edit tutorial completion status
                storage.write(
                    key: "reservationTutorialComplete",
                    value:
                        "completed"); // Mark the reservation tutorial as completed
                final userID = await storage.read(
                    key: "userID"); // Read the user ID from secure storage
                TutorialManager.markCurrentSession(
                    userID!); // Mark the current session as completed
                TutorialManager
                    .markFirstLaunchComplete(); // Mark the first launch as completed
              },
              child: Text(
                "Skip",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkTheme
                        ? darkColorScheme.primary
                        : lightColorScheme.primary),
              )),
        );
      },

      // This section specifies where the "Skip" button should be hidden during the tutorial
      hideFloatingActionWidgetForShowcase: [saveButtonKey, dogSaveButtonKey],

      // This is the configuration for the "Next" and "Previous" buttons in the tutorial
      globalTooltipActionConfig: const TooltipActionConfig(
        alignment: MainAxisAlignment.end,
        actionGap: 10,
        gapBetweenContentAndAction: 10,
        position: TooltipActionPosition.outside,
      ),

      // This is the list of "standard" button actions that will be available during the tutorial
      globalTooltipActions: [
        // Previous button
        TooltipActionButton(
          type: TooltipDefaultActionType.previous,
          leadIcon: ActionButtonIcon(
            icon: Icon(
              Icons.arrow_back_ios,
              size: 16,
              color: isDarkTheme
                  ? darkColorScheme.onPrimary
                  : lightColorScheme.onPrimary,
            ), // Icon
          ), // ActionButtonIcon
          name: "Previous",
          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkTheme
                  ? darkColorScheme.onPrimary
                  : lightColorScheme.onPrimary),
          // Specify where the "Previous" button should be hidden during the tutorial
          hideActionWidgetForShowcase: [
            homePageKey,
            dogCardKey,
            reservationCardKey,
            saveButtonKey,
            dogSaveButtonKey,
            reservationDetailsKey
          ], // hide on first tutorial popup
          backgroundColor:
              isDarkTheme ? darkColorScheme.primary : lightColorScheme.primary,
        ),

        // Next button
        TooltipActionButton(
            type: TooltipDefaultActionType.next,
            name: "Next",
            textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkTheme
                    ? darkColorScheme.onPrimaryContainer
                    : lightColorScheme.onPrimaryContainer),
            hideActionWidgetForShowcase: [
              homePageNavBarButtonKey
            ], // hide on last showcase
            backgroundColor: isDarkTheme
                ? darkColorScheme.primaryContainer
                : lightColorScheme.primaryContainer),
      ],

      /// called every time each coach mark started
      // onStart: (index, key) {
      //   print("TAGGS : onStart $index Skey");
      // },
      //
      /// called every time each coach mark completed
      // onComplete: (index, key) {
      //   print("TAGGS : onComplete $index Skey");
      // },
      //
      /// called every group of coach mark completed onFinish
      onFinish: () async {
        print("Tutorial finished");
        // Save the tutorial completion state to secure storage
        await TutorialManager.handleTutorialCompletion();
      },
      // This is the blur effect applied to the background during the tutorial
      blurValue: 5,
      // This is the configuration for the barrier that prevents interaction with the background during the tutorial
      disableBarrierInteraction: true,
    );
  }
}
