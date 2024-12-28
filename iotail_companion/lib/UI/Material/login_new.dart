import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart';

import '../../util/rive_controller.dart';
import '../../util/requests.dart' as requests;

class LoginNew extends StatefulWidget {
  const LoginNew({Key? key}) : super(key: key);

  @override
  _LoginNewState createState() => _LoginNewState();
}

class _LoginNewState extends State<LoginNew> {
  final RiveAnimationControllerHelper riveHelper =
      RiveAnimationControllerHelper();

  bool _obscureText = true;
  bool isSignup = false;
  late String ip;
  late String email;
  late String password;
  late FlutterSecureStorage storage;
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  Future<void> getIP() async {
    ip = (await storage.read(key: "ip"))!;
  }

  Future<void> login(String ip, String email, String password) async {
    ip = (await storage.read(key: "ip"))!;
    Map tmp = await requests.login(ip, email, password);
    storage.write(key: "userID", value: tmp["userID"]);
    storage.write(key: "email", value: email);
    storage.write(key: "password", value: password);
    storage.write(key: "token", value: tmp["token"]);
  }

  @override
  void initState() {
    super.initState();
    storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    riveHelper.loadRiveFile('assets/doggo.riv').then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getIP(),
      builder: (context, snapshot) => Scaffold(
        appBar: AppBar(
          title: const Text("IoTail"),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              riveHelper.riveArtboard != null
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height / 4,
                      child: Rive(
                        artboard: riveHelper.riveArtboard!,
                        fit: BoxFit.contain,
                      ),
                    )
                  : const SizedBox.shrink(),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width / 10),
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 8,
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        TextFormField(
                            onChanged: (value) => email = value,
                            textCapitalization: TextCapitalization.none,
                            decoration: InputDecoration(
                              labelText: "Email",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(width: 0.5)),
                              prefixIcon: Icon(Icons.email),
                            )),
                        SizedBox(height: 8),
                        TextFormField(
                          obscureText: _obscureText,
                          textCapitalization: TextCapitalization.none,
                          onChanged: (value) => password = value,
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(width: 0.5)),
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              highlightColor: Colors.transparent,
                              icon: Icon(_obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                        ),
                        if (isSignup) SizedBox(height: 8),
                        if (isSignup)
                          TextFormField(
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              labelText: "Confirm Password",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(width: 0.5)),
                              prefixIcon: Icon(Icons.lock),
                              suffixIcon: IconButton(
                                highlightColor: Colors.transparent,
                                icon: Icon(_obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                            ),
                          ),
                        if (!isSignup)
                          TextButton(
                            onPressed: () {},
                            style: ButtonStyle(
                              overlayColor:
                                  WidgetStateProperty.all(Colors.transparent),
                            ),
                            child: const Text("Forgot Password?"),
                          ),
                        if (isSignup) SizedBox(height: 8),
                        ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                                Theme.of(context).colorScheme.primary),
                          ),
                          onPressed: () async {
                            if (isSignup) {
                              // signup
                            } else {
                              await login(ip, email, password);
                              if (context.mounted) context.go("/Navigation");
                            }
                          },
                          child: Text(
                            isSignup ? "SIGN UP" : "LOG IN",
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isSignup = !isSignup;
                            });
                          },
                          style: ButtonStyle(
                            overlayColor:
                                WidgetStateProperty.all(Colors.transparent),
                          ),
                          child: Text(isSignup ? "LOG IN" : "SIGN UP"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
