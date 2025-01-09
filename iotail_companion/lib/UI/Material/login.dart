import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rive/rive.dart' hide LinearGradient, Image;
import 'package:go_router/go_router.dart';

import 'package:iotail_companion/UI/Material/terms_and_conditions.dart';
import 'package:iotail_companion/util/rive_controller.dart';
import 'package:iotail_companion/util/requests.dart' as requests;

class LoginWithRive extends StatefulWidget {
  final String ip;
  const LoginWithRive({super.key, required this.ip});

  @override
  _LoginWithRiveState createState() => _LoginWithRiveState();
}

const users = {
  'ale@gmail.com': '1234',
  'dribbble@gmail.com': '12345',
  'hunter@gmail.com': 'hunter',
};

class _LoginWithRiveState extends State<LoginWithRive> {
  final RiveAnimationControllerHelper riveHelper =
      RiveAnimationControllerHelper();

  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();

  bool _isAnimating = false;
  bool _passwordFieldFocused = false;

  late FlutterSecureStorage storage;
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  late final String token;
  late final String userID;

  @override
  void initState() {
    super.initState();
    storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    // Carica il file Rive all'avvio
    riveHelper.loadRiveFile('assets/doggo.riv').then((_) {
      setState(() {});
    });

    emailFocusNode.addListener(_handleUsernameFocus);
    passwordFocusNode.addListener(_handlePasswordFocus);
    confirmPasswordFocusNode.addListener(_handlePasswordFocus);
  }

  @override
  void dispose() {
    super.dispose();

    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
  }

  void _handleUsernameFocus() {
    if (_isAnimating) return;
    if (emailFocusNode.hasFocus) {
      riveHelper.addIdle2Controller();
      Future.delayed(const Duration(seconds: 1), () {
        riveHelper.addDownLeftController();
      });
    } else {
      riveHelper.addIdle2Controller();
    }
  }

  void _handlePasswordFocus() {
    if (_isAnimating) return;
    if (passwordFocusNode.hasFocus || confirmPasswordFocusNode.hasFocus) {
      _passwordFieldFocused = true;
      riveHelper.addHandsUpController();
    } else if (_passwordFieldFocused) {
      riveHelper.playSequentialAnimationControllers([
        riveHelper.addHandsDownController,
        riveHelper.addIdle2Controller,
      ]);
      _passwordFieldFocused = false;
    }
  }

  Future<String?> _authUser(LoginData data) async {
    if (_isAnimating) {
      return null; // Evita di riattivare l'animazione se già in corso
    }

    setState(() {
      _isAnimating = true; // Blocca i listener
    });

    Map tmp = await requests.login(widget.ip, data.name, data.password);
    if (tmp.containsKey("error")) {
      riveHelper.playSequentialAnimationControllers([
        riveHelper.addFailController,
        riveHelper.addIdle2Controller,
      ]);
      return tmp["error"];
    }
    userID = tmp["userID"];
    storage.write(key: "userID", value: tmp["userID"]);
    storage.write(key: "email", value: data.name);
    storage.write(key: "password", value: data.password);
    token = tmp["token"];
    storage.write(key: "token", value: tmp["token"]);
    riveHelper.addSuccessController();
    setState(() {
      _isAnimating = false; // Riattiva i listener dopo l'animazione
    });
    return null;
  }

  Future<String?> _signupUser(SignupData data) async {
    if (_isAnimating) {
      return null; // Evita di riattivare l'animazione se già in corso
    }

    setState(() {
      _isAnimating = true; // Blocca i listener
    });

    // debugPrint('Signup Name: ${data.name}, Password: ${data.password}');
    Map tmp = await requests.register(widget.ip, {
      "name": data.additionalSignupData!['Full Name']!,
      "email": data.name!,
      "password": data.password!,
      "phone": data.additionalSignupData!['Phone Number']!,
    });
    if (tmp.containsKey("message")) {
      riveHelper.playSequentialAnimationControllers([
        riveHelper.addFailController,
        riveHelper.addIdle2Controller,
      ]);
      return tmp["message"];
    }
    userID = tmp["userID"];
    storage.write(key: "userID", value: tmp["userID"]);
    storage.write(key: "email", value: data.name);
    storage.write(key: "password", value: data.password);
    token = tmp["token"];
    storage.write(key: "token", value: tmp["token"]);
    riveHelper.addSuccessController();
    setState(() {
      _isAnimating = false; // Riattiva i listener dopo l'animazione
    });
    return null;
  }

  Future<String?> _signupConfirm(String error, LoginData data) async {
    return Future.delayed(const Duration(seconds: 2)).then((_) {
      return null;
    });
  }

  Future<String?> _recoverPassword(String email) async {
    // debugPrint('Name: $name');
    Map<String, dynamic> tmp =
        await requests.recover_password(widget.ip, email);
    if ((tmp["message"] as String).contains("Failed")) {
      riveHelper.playSequentialAnimationControllers([
        riveHelper.addFailController,
        riveHelper.addIdle2Controller,
      ]);
      return tmp["message"];
    }
    riveHelper.addIdle2Controller();
    setState(() {
      _isAnimating = false; // Riattiva i listener dopo l'animazione
    });
    return null;
  }

  Future<String?> _resetPassword(String recovery_code, LoginData data) async {
    Map tmp = await requests.reset_password(
        widget.ip, recovery_code, data.name, data.password);
    if ((tmp["message"] as String).contains("Failed")) {
      riveHelper.playSequentialAnimationControllers([
        riveHelper.addFailController,
        riveHelper.addIdle2Controller,
      ]);
      return tmp["message"];
    }
    riveHelper.addIdle2Controller();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).colorScheme.inversePrimary,
              Theme.of(context).colorScheme.tertiary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'IoTail',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        forceMaterialTransparency: true,
      ),
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          // Nascondi la tastiera e reimposta lo stato idle
          FocusScope.of(context).unfocus();
          // riveHelper.addIdle2Controller();
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height,
                ),
                child: FlutterLogin(
                  theme: LoginTheme(
                    pageColorLight: Theme.of(context).colorScheme.surface,
                    pageColorDark: Theme.of(context).colorScheme.surface,
                    primaryColor: Theme.of(context).colorScheme.primary,
                    errorColor: Theme.of(context).colorScheme.error,
                    accentColor: Theme.of(context).colorScheme.secondary,
                    cardTheme: CardTheme(
                      color: Theme.of(context).colorScheme.surface,
                      surfaceTintColor:
                          Theme.of(context).colorScheme.surfaceTint,
                      shadowColor: Theme.of(context).colorScheme.shadow,
                      elevation: 1,
                    ),
                    buttonTheme: LoginButtonTheme(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      elevation: 1,
                    ),
                    buttonStyle: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                    bodyStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                    cardInitialHeight: MediaQuery.of(context).size.height / 2,
                  ),
                  userFocusNode: emailFocusNode,
                  passwordFocusNode: passwordFocusNode,
                  confirmPasswordFocusNode: confirmPasswordFocusNode,
                  logo: riveHelper.riveArtboard != null
                      ? Rive(
                          artboard: riveHelper.riveArtboard!,
                          fit: BoxFit.contain,
                        )
                      : const SizedBox.shrink(),
                  onLogin: _authUser,
                  onSignup: _signupUser,
                  // onConfirmSignup: ,
                  onRecoverPassword: _recoverPassword,
                  onConfirmRecover: _resetPassword,
                  onSubmitAnimationCompleted: () {
                    context.go("/Navigation", extra: {
                      "ip": widget.ip,
                      "token": token,
                      "userID": userID
                    });
                  },
                  additionalSignupFields: const [
                    UserFormField(
                      keyName: 'Full Name',
                      userType: LoginUserType.firstName,
                      icon: Icon(FontAwesomeIcons.userLarge),
                    ),
                    UserFormField(
                      keyName: 'Phone Number',
                      userType: LoginUserType.phone,
                      icon: Icon(FontAwesomeIcons.phone),
                    ),
                  ],
                  loginAfterSignUp: false,
                  scrollable: true,
                  termsOfService: [
                    TermOfService(
                      id: 'general-term',
                      mandatory: true,
                      text: 'I agree the Terms of service and Privacy Policy',
                      linkUrl:
                          'https://www.youtube.com/watch?v=dQw4w9WgXcQ&pp=ygUIcmlja3JvbGw%3D',
                    ),
                  ],
                  //savedEmail:
                  // footer: "© 2024 IoTail",
                  //onSwitchToAdditionalFields: ,
                ),
              ),
            ),
            const Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: TermsAndConditionsText(),
            ),
          ],
        ),
      ),
    );
  }
}
