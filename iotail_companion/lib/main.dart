import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:showcaseview/showcaseview.dart';
import 'firebase_options.dart';

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
  WidgetsFlutterBinding.ensureInitialized();
  await RiveFile.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseApi.instance.initialize();
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );
  await FlutterSecureStorage(aOptions: _getAndroidOptions())
      .write(key: "ip", value: "192.168.0.243");
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
          breeds: extra["breeds"],
          onEdit: extra["onEdit"],
        );
      }),
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
      }),
]);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    final isDarkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
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
      ),
      globalFloatingActionWidget: (showcaseContext) {
        return FloatingActionWidget(
          bottom: MediaQuery.paddingOf(context).bottom,
          left: 24,
          child: TextButton(
              onPressed: () {
                ShowCaseWidget.of(showcaseContext).dismiss();
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
      hideFloatingActionWidgetForShowcase: [saveButtonKey],
      globalTooltipActionConfig: const TooltipActionConfig(
        alignment: MainAxisAlignment.end,
        actionGap: 10,
        gapBetweenContentAndAction: 10,
        position: TooltipActionPosition.outside,
      ),
      globalTooltipActions: [
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
          hideActionWidgetForShowcase: [
            homePageKey,
            saveButtonKey,
          ], // hide on first showcase
          backgroundColor:
              isDarkTheme ? darkColorScheme.primary : lightColorScheme.primary,
        ),
        TooltipActionButton(
            type: TooltipDefaultActionType.next,
            name: "Next",
            textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkTheme
                    ? darkColorScheme.onPrimaryContainer
                    : lightColorScheme.onPrimaryContainer),
            hideActionWidgetForShowcase: [
              mapNavBarButtonKey,
              saveButtonKey
            ], // hide on last showcase
            backgroundColor: isDarkTheme
                ? darkColorScheme.primaryContainer
                : lightColorScheme.primaryContainer),
      ],

      // /// called every time each coach mark started
      // onStart: (index, key) {
      //   print("TAGGS : onStart $index Skey");
      // },
      //
      // /// called every time each coach mark completed
      // onComplete: (index, key) {
      //   print("TAGGS : onComplete $index Skey");
      // },
      //
      /// called every group of coach mark completed onFinish
      onFinish: () async {
        print("Tutorial finished");
        await TutorialManager.handleTutorialCompletion();
      },
      blurValue: 5,
      disableBarrierInteraction: true,
    );
  }
}
