import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rive/rive.dart' hide LinearGradient, Image;
import 'package:go_router/go_router.dart';

import 'package:iotail_companion/UI/Material/terms_and_conditions.dart';
import 'package:iotail_companion/util/rive_controller.dart';
import 'package:iotail_companion/util/requests.dart' as requests;

/// Login screen with Rive animation
class LoginWithRive extends StatefulWidget {
  final String ip; // Get the IP address from the splash screen
  const LoginWithRive({super.key, required this.ip});

  @override
  _LoginWithRiveState createState() => _LoginWithRiveState();
}

class _LoginWithRiveState extends State<LoginWithRive> {
  final RiveAnimationControllerHelper riveHelper =
      RiveAnimationControllerHelper(); // Helper for Rive animations

  final FocusNode emailFocusNode = FocusNode(); // Focus node for email input
  final FocusNode passwordFocusNode =
      FocusNode(); // Focus node for password input
  final FocusNode confirmPasswordFocusNode =
      FocusNode(); // Focus node for confirm password input

  bool _isAnimating =
      false; // Flag to prevent multiple animations at the same time
  bool _passwordFieldFocused =
      false; // Flag to track if the password field is focused

  late FlutterSecureStorage
      storage; // Declaring secure storage variable for persistently storing data or writing precedently stored data. This allows to persist information after the app is closed.
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      ); // Options for Android secure storage

  late final String token;
  late final String userID;

  @override
  void initState() {
    super.initState();
    storage = FlutterSecureStorage(
        aOptions:
            _getAndroidOptions()); // Initialize secure storage with Android options
    // Carica il file Rive all'avvio
    riveHelper.loadRiveFile('assets/doggo.riv').then((_) {
      setState(
          () {}); // Trigger a rebuild to display the Rive animation after it is loaded
    });

    emailFocusNode.addListener(
        _handleUsernameFocus); // Add listener for email focus changes
    passwordFocusNode.addListener(
        _handlePasswordFocus); // Add listener for password focus changes
    confirmPasswordFocusNode.addListener(
        _handlePasswordFocus); // Add listener for confirm password focus changes
  }

  @override
  void dispose() {
    super.dispose();

    emailFocusNode.dispose(); // Dispose of email focus node
    passwordFocusNode.dispose(); // Dispose of password focus node
    confirmPasswordFocusNode
        .dispose(); // Dispose of confirm password focus node
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

  /// Handles the focus state of the password and confirm password fields.
  void _handlePasswordFocus() {
    if (_isAnimating) return; // Prevents focus handling during animations
    if (passwordFocusNode.hasFocus || confirmPasswordFocusNode.hasFocus) {
      _passwordFieldFocused =
          true; // Set the flag to true when password field is focused
      riveHelper
          .addHandsUpController(); // Play the hands up animation when password field is focused
    } else if (_passwordFieldFocused) {
      // If the password field was focused and now lost focus
      riveHelper.playSequentialAnimationControllers([
        riveHelper.addHandsDownController, // Play the hands down animation
        riveHelper.addIdle2Controller, // Then return to idle state
      ]);
      _passwordFieldFocused =
          false; // Reset the flag when password field loses focus
    }
  }

  /// Authenticates the user with the provided login data.
  Future<String?> _authUser(LoginData data) async {
    if (_isAnimating) {
      return null; // Avoid re-triggering the animation if already in progress
    }

    setState(() {
      _isAnimating = true; // Block the listeners to prevent multiple animations
    });

    final String firebaseToken = await storage.read(key: "FirebaseToken") ??
        ""; // Retrieve the Firebase token from the storage
    Map tmp = await requests.login(widget.ip, data.name, data.password,
        firebaseToken); // Make a login request with the provided data and Firebase token to get the token authentication token for the future requests
    if (tmp.containsKey("error")) {
      // if the response contains an error
      riveHelper.playSequentialAnimationControllers([
        riveHelper.addFailController, // Play the fail animation
        riveHelper.addIdle2Controller, // Then return to idle state
      ]);
      return tmp["error"]; // Return the error message
    }
    userID = tmp["userID"]; // Store the user ID from the response
    storage.write(
        key: "userID",
        value: tmp["userID"]); // Write the user ID to the storage
    storage.write(
        key: "email", value: data.name); // Write the email to the storage
    storage.write(
        key: "password",
        value: data.password); // Write the password to the storage
    token = tmp["token"]; // Store the token from the response
    storage.write(
        key: "token", value: tmp["token"]); // Write the token to the storage
    riveHelper.addSuccessController(); // Play the success animation
    setState(() {
      _isAnimating = false; // Reactivate the listeners after the animation
    });
    return null; // Return null to indicate successful authentication
  }

  /// Signs up a new user with the provided signup data.
  Future<String?> _signupUser(SignupData data) async {
    if (_isAnimating) {
      return null; // Avoid re-triggering the animation if already in progress
    }

    setState(() {
      _isAnimating = true; // Block the listeners to prevent multiple animations
    });

    Map tmp = await requests.register(widget.ip, {
      "email": data.name!,
    }); // Make a registration request with the provided email
    if ((tmp["message"] as String).contains("Failed")) {
      riveHelper.playSequentialAnimationControllers([
        riveHelper.addFailController,
        riveHelper.addIdle2Controller,
      ]); // Play the fail animation if the registration failed
      return tmp["message"]; // Return the error message
    }
    riveHelper
        .addSuccessToIdleController(); // Play the success animation and then return to idle state
    setState(() {
      _isAnimating = false; // Reactivate the listeners after the animation
    });
    return null; // Return null to indicate successful signup
  }

  /// Confirms the signup with the provided registration code and additional signup data.
  Future<String?> _signupConfirm(
      String registration_code, SignupData data) async {
    final String firebaseToken = await storage.read(key: "FirebaseToken") ??
        ""; // Retrieve the Firebase token from the storage
    Map tmp = await requests.confirm_registration(widget.ip, {
      "name": data.additionalSignupData!['Full Name']!,
      "email": data.name!,
      "password": data.password!,
      "phone": data.additionalSignupData!['Phone Number']!,
      "registration_code": registration_code,
      "firebaseToken": firebaseToken,
    }); // Make a confirmation request with the provided data and Firebase token
    if (tmp.containsKey("message")) {
      // if the response contains a message
      riveHelper.playSequentialAnimationControllers([
        riveHelper.addFailController, // Play the fail animation
        riveHelper.addIdle2Controller, // Then return to idle state
      ]);
      return tmp["message"]; // Return the error message
    }
    userID = tmp["userID"]; // Store the user ID from the response
    storage.write(
        key: "userID",
        value: tmp["userID"]); // Write the user ID to the storage
    storage.write(
        key: "email", value: data.name); // Write the email to the storage
    storage.write(
        key: "password",
        value: data.password); // Write the password to the storage
    token = tmp["token"]; // Store the token from the response
    storage.write(
        key: "token", value: tmp["token"]); // Write the token to the storage
    riveHelper.addSuccessController(); // Play the success animation
    setState(() {
      _isAnimating = false; // Reactivate the listeners after the animation
    });
    return null; // Return null to indicate successful signup confirmation
  }

  /// Starts the password recovery process for the provided email.
  Future<String?> _recoverPassword(String email) async {
    Map<String, dynamic> tmp = await requests.recover_password(widget.ip,
        email); // Make a password recovery request with the provided email
    if ((tmp["message"] as String).contains("Failed")) {
      // if the response contains an error message
      riveHelper.playSequentialAnimationControllers([
        riveHelper.addFailController, // Play the fail animation
        riveHelper.addIdle2Controller, // Then return to idle state
      ]);
      return tmp["message"]; // Return the error message
    }
    riveHelper
        .addIdle2Controller(); // Play the idle animation after successful recovery
    setState(() {
      _isAnimating = false; // Reactivate the listeners after the animation
    });
    return null; // Return null to indicate successful password recovery
  }

  /// Resets the password using the provided recovery code and new login data.
  Future<String?> _resetPassword(String recovery_code, LoginData data) async {
    Map tmp = await requests.reset_password(widget.ip, recovery_code, data.name,
        data.password); // Make a password reset request with the provided recovery code and new login data
    if ((tmp["message"] as String).contains("Failed")) {
      // if the response contains an error message
      riveHelper.playSequentialAnimationControllers([
        riveHelper.addFailController, // Play the fail animation
        riveHelper.addIdle2Controller, // Then return to idle state
      ]);
      return tmp["message"]; // Return the error message
    }
    riveHelper.playSequentialAnimationControllers([
      riveHelper.addSuccessToIdleController,
      riveHelper.addIdleController
    ]); // Play the success animation and then return to idle state
    return null; // Return null to indicate successful password reset
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
          ).createShader(
              bounds), // Apply a gradient shader to the title, from top left to bottom right
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
          // Hide the keyboard when tapping outside of text fields and return to idle state
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            // Background Rive animation
            SingleChildScrollView(
              physics:
                  const NeverScrollableScrollPhysics(), // Disable scrolling for the background
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
                  logo: riveHelper.riveArtboard !=
                          null // if the Rive artboard is loaded
                      ? Rive(
                          artboard: riveHelper.riveArtboard!,
                          fit: BoxFit.contain,
                        ) // Display the Rive animation
                      : const SizedBox.shrink(), // Otherwise, show an empty box
                  onLogin: _authUser,
                  onSignup: _signupUser,
                  onConfirmSignup: _signupConfirm,
                  onRecoverPassword: _recoverPassword,
                  onConfirmRecover: _resetPassword,
                  onSubmitAnimationCompleted: () {
                    context.go("/Navigation", extra: {
                      "ip": widget.ip,
                      "token": token,
                      "userID": userID
                    }); // Navigate to the main navigation screen after successful login or signup
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
                  loginAfterSignUp: true,
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
                ),
              ),
            ),
            // Terms and Conditions text at the bottom
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
