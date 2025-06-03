import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import 'package:iotail_companion/util/requests.dart' as requests;

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
  late Future<String?> userID;
  late Future<String?> ip;
  late Future<String> token;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    userID = storage.read(key: "userID");
    ip = storage.read(key: "ip");
  }

  Future<String> refreshToken(String ip) async {
    String? email = await storage.read(key: "email");
    String? password = await storage.read(key: "password");
    final String? firebaseToken = await storage.read(key: "FirebaseToken");
    Map tmp = await requests.login(ip, email!, password!, firebaseToken!);
    await storage.write(key: "token", value: tmp["token"]);
    return tmp["token"];
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([userID, ip]),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data![0] == null) {
              Future.delayed(const Duration(seconds: 6),
                  () => context.go("/Login", extra: snapshot.data![1]));
              return _buildSplashScreen(context);
            }
            String userID_val = snapshot.data![0]!;
            String ip_val = snapshot.data![1]!;
            token = refreshToken(ip_val);
            return FutureBuilder(
              future: token,
              builder: (context, tokenSnapshot) {
                if (tokenSnapshot.hasError) {
                  return Scaffold(
                    body: Center(child: Text('Error: ${tokenSnapshot.error}')),
                    floatingActionButton: FloatingActionButton(
                      onPressed: () async {
                        token = refreshToken(ip_val);
                      },
                      child: Icon(Icons.refresh),
                    ),
                  );
                } else if (tokenSnapshot.hasData) {
                  String token_val = tokenSnapshot.data!;
                  Future.delayed(const Duration(seconds: 6), () {
                    context.go("/Navigation", extra: {
                      "userID": userID_val,
                      "ip": ip_val,
                      "token": token_val,
                    });
                  });
                  return _buildSplashScreen(context);
                } else {
                  return _buildSplashScreen(context);
                }
              },
            );
          } else {
            return _buildSplashScreen(context);
          }
        });
  }

  Widget _buildSplashScreen(BuildContext context) {
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
