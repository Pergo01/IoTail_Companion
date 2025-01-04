import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rive/rive.dart' hide LinearGradient, Image;
import 'package:go_router/go_router.dart';
import '/util/rive_controller.dart';
import 'terms_and_conditions.dart';

class LoginWithRive extends StatefulWidget {
  const LoginWithRive({super.key});

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

  @override
  void initState() {
    super.initState();

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
    if (_isAnimating)
      return null; // Evita di riattivare l'animazione se già in corso

    setState(() {
      _isAnimating = true; // Blocca i listener
    });

    debugPrint('Name: ${data.name}, Password: ${data.password}');
    return Future.delayed(const Duration(milliseconds: 2250)).then((_) {
      if (!users.containsKey(data.name)) {
        riveHelper.playSequentialAnimationControllers([
          riveHelper.addFailController,
          riveHelper.addIdle2Controller,
        ]);
        return 'User does not exist';
      }
      if (users[data.name] != data.password) {
        riveHelper.playSequentialAnimationControllers([
          riveHelper.addFailController,
          riveHelper.addIdle2Controller,
        ]);
        return 'Password does not match';
      } else {
        riveHelper.addSuccessController();
      }
      return null;
    }).whenComplete(() {
      setState(() {
        _isAnimating = false; // Riattiva i listener dopo l'animazione
      });
    });
  }

  Future<String?> _signupUser(SignupData data) async {
    // if (_isAnimating)
    //   return null; // Evita di riattivare l'animazione se già in corso

    setState(() {
      _isAnimating = true; // Blocca i listener
    });

    debugPrint('Signup Name: ${data.name}, Password: ${data.password}');
    return Future.delayed(const Duration(milliseconds: 2250)).then((_) {
      if (users.containsKey(data.name)) {
        riveHelper.playSequentialAnimationControllers([
          riveHelper.addFailController,
          riveHelper.addIdle2Controller,
        ]);
        return 'User already exists';
      } else {
        riveHelper.addIdle2Controller();
      }
      return null;
    }).whenComplete(() {
      setState(() {
        _isAnimating = false; // Riattiva i listener dopo l'animazione
      });
    });
  }

  Future<String?> _recoverPassword(String name) {
    debugPrint('Name: $name');
    return Future.delayed(const Duration(milliseconds: 2250)).then((_) {
      if (!users.containsKey(name)) {
        riveHelper.playSequentialAnimationControllers([
          riveHelper.addFailController,
          riveHelper.addIdle2Controller,
        ]);
        return 'User does not exist';
      } else {
        riveHelper.addIdle2Controller();
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    cardInitialHeight: MediaQuery.of(context).size.height - 250,
                  ),
                  userFocusNode: emailFocusNode,
                  passwordFocusNode: passwordFocusNode,
                  confirmPasswordFocusNode: confirmPasswordFocusNode,
                  // logo: Image.asset(
                  //   "assets/IoTail.gif",
                  // ).image,
                  //title: "Benvenuto",
                  onLogin: _authUser,
                  onSignup: _signupUser,
                  onRecoverPassword: _recoverPassword,
                  onSubmitAnimationCompleted: () {
                    context.go("/Navigation");
                  },
                  additionalSignupFields: const [
                    UserFormField(
                      keyName: 'Username',
                      icon: Icon(FontAwesomeIcons.userLarge),
                    ),
                    UserFormField(keyName: 'Name'),
                    UserFormField(keyName: 'phone'),
                    UserFormField(keyName: 'codicefiscale'),
                    UserFormField(keyName: 'address'),
                    UserFormField(keyName: 'cap'),
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
            // Rive animation above the login screen
            Positioned(
              top: MediaQuery.of(context).size.height - 816,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height / 4,
              child: riveHelper.riveArtboard != null
                  ? Rive(
                      artboard: riveHelper.riveArtboard!,
                      fit: BoxFit.contain,
                    )
                  : const SizedBox.shrink(),
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
