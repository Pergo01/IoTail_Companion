import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import 'package:iotail_companion/util/requests.dart' as requests;

/// SplashScreen widget that displays a splash screen with an animation from a GIF file.
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late FlutterSecureStorage
      storage; // Declaring secure storage variable for persistently storing data or writing precedently stored data. This allows to persist information after the app is closed.

  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      ); // Options for Android to use encrypted shared preferences for secure storage.
  late Future<String?>
      userID; // Future to hold the userID read from the storage.
  late Future<String?>
      ip; // Future to hold the IP address read from the storage.
  late Future<String> token; // Future to hold the token that will be refreshed.

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode
        .immersive); // Hides the system UI for a more immersive experience.
    storage = FlutterSecureStorage(
        aOptions:
            _getAndroidOptions()); // Initializing secure storage with Android options for encrypted shared preferences.
    userID =
        storage.read(key: "userID"); // Reading the userID from the storage.
    ip = storage.read(key: "ip"); // Reading the IP address from the storage.
  }

  /// Refreshes the token by logging in with the stored email and password.
  Future<String> refreshToken(String ip) async {
    String? email =
        await storage.read(key: "email"); // Reading the email from the storage.
    String? password = await storage.read(
        key: "password"); // Reading the password from the storage.
    final String? firebaseToken = await storage.read(
        key: "FirebaseToken"); // Reading the Firebase token from the storage.
    Map tmp = await requests.login(ip, email!, password!,
        firebaseToken); // Logging in with the stored email and password, and getting the token.
    await storage.write(
        key: "token", value: tmp["token"]); // Writing the token to the storage.
    return tmp["token"]; // Returning the token.
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay
            .values); // Restoring the system UI mode to manual with all overlays visible.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([
          userID,
          ip
        ]), // Waiting for both userID and IP to be read from the storage.
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // If both userID and IP are successfully read from the storage.
            if (snapshot.data![0] == null) {
              // If userID is null, redirect to Login page.
              Future.delayed(
                  const Duration(seconds: 6),
                  () => context.go("/Login",
                      extra: snapshot.data![
                          1])); // Wait for 6 seconds to show the animation and then navigate to the Login page, passing the IP address as an extra parameter.
              return _buildSplashScreen(
                  context); // Build the splash screen with the animation and logo.
            }
            String userID_val = snapshot
                .data![0]!; // Extracting the userID from the snapshot data.
            String ip_val = snapshot
                .data![1]!; // Extracting the IP address from the snapshot data.
            token = refreshToken(
                ip_val); // Refreshing the authentication token using the IP address.
            return FutureBuilder(
              future: token, // Waiting for the token to be refreshed.
              builder: (context, tokenSnapshot) {
                if (tokenSnapshot.hasError) {
                  // If there is an error while refreshing the token.
                  return Scaffold(
                    body: Center(child: Text('Error: ${tokenSnapshot.error}')),
                    floatingActionButton: FloatingActionButton(
                      onPressed: () async {
                        token = refreshToken(
                            ip_val); // Retry refreshing the token when the button is pressed.
                      },
                      child: Icon(Icons.refresh),
                    ),
                  ); // Displaying an error message and a button to retry refreshing the token.
                } else if (tokenSnapshot.hasData) {
                  // If the token is successfully refreshed.
                  String token_val = tokenSnapshot
                      .data!; // Extracting the refreshed token from the snapshot data.
                  Future.delayed(const Duration(seconds: 6), () {
                    context.go("/Navigation", extra: {
                      "userID": userID_val,
                      "ip": ip_val,
                      "token": token_val,
                    });
                  }); // Wait for 6 seconds to show the animation and then navigate to the Navigation page, passing userID, IP address, and token as extra parameters.
                  return _buildSplashScreen(
                      context); // Build the splash screen with the animation and logo.
                } else {
                  return _buildSplashScreen(
                      context); // If the token is still being refreshed, show the splash screen.
                }
              },
            );
          } else {
            return _buildSplashScreen(
                context); // If userID or IP is not yet available, show the splash screen. THE IP ADDRESS IS ALWAYS AVAILABLE BECAUSE IT IS SAVED IN THE STORAGE WHEN LAUNCHING THE APP.
          }
        });
  }

  /// Builds the splash screen with a gradient background, an animated GIF, and the app name.
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
        ), // Gradient for the title text from top left to bottom right
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Image.asset(
                'assets/IoTail.gif',
                height: 200,
                width: 200,
              ),
            ), // Displaying the animated GIF from the assets folder.
            const SizedBox(
              height: 20,
            ), // Adding some space between the GIF and the title text.
            Center(
              child: Text(
                "IoTail",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ), // Show the app name
          ],
        ),
      ),
    );
  }
}
