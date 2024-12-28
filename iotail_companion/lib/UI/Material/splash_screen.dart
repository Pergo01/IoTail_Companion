import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../util/requests.dart' as requests;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late FlutterSecureStorage storage;
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );
  late String? userID;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    storage = FlutterSecureStorage(aOptions: _getAndroidOptions());

    getID();
    Future.delayed(const Duration(seconds: 6), () {
      if (userID == null) {
        context.go("/Login");
      } else {
        refreshToken();
        context.go("/Navigation");
      }
    });
  }

  Future<void> refreshToken() async {
    String? ip = await storage.read(key: "ip");
    String? email = await storage.read(key: "email");
    String? password = await storage.read(key: "password");
    Map tmp = await requests.login(ip!, email!, password!);
    storage.write(key: "token", value: tmp["token"]);
  }

  Future<void> getID() async {
    userID = await storage.read(key: "userID");
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.inversePrimary,
              Theme.of(context).colorScheme.tertiary,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [0.3, 3.0],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Image.asset(
                'assets/IoTail.gif',
                height: 200,
                width: 200,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: Text(
                "IoTail",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ),
            // Center(
            //   child: CircularProgressIndicator(),
            // ),
          ],
        ),
      ),
    );
  }
}
