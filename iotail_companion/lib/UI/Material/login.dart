import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

const users = {
  'dribbble@gmail.com': '12345',
  'hunter@gmail.com': 'hunter',
};

class _LoginState extends State<Login> {
  Duration get loginTime => const Duration(milliseconds: 2250);

  Future<String?> _authUser(LoginData data) {
    debugPrint('Name: ${data.name}, Password: ${data.password}');
    return Future.delayed(loginTime).then((_) {
      if (!users.containsKey(data.name)) {
        return 'User not exists';
      }
      if (users[data.name] != data.password) {
        return 'Password does not match';
      }
      return null;
    });
  }

  Future<String?> _signupUser(SignupData data) {
    debugPrint('Signup Name: ${data.name}, Password: ${data.password}');
    return Future.delayed(loginTime).then((_) {
      return null;
    });
  }

  Future<String?> _recoverPassword(String name) {
    debugPrint('Name: $name');
    return Future.delayed(loginTime).then((_) {
      if (!users.containsKey(name)) {
        return 'User not exists';
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("IoTail")),
      body: FlutterLogin(
        theme: LoginTheme(
            pageColorLight: Theme.of(context).colorScheme.background,
            pageColorDark: Theme.of(context).colorScheme.background,
            primaryColor: Theme.of(context).colorScheme.primary,
            errorColor: Theme.of(context).colorScheme.error,
            accentColor: Theme.of(context).colorScheme.secondary,
            cardTheme: CardTheme(
                color: Theme.of(context).colorScheme.background,
                surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                shadowColor: Theme.of(context).colorScheme.shadow,
                elevation: 1),
            buttonTheme: LoginButtonTheme(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                elevation: 1),
            buttonStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer),
            bodyStyle:
                TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        title: "Benvenuto",
        onLogin: _authUser,
        onSignup: _signupUser,
        onRecoverPassword: _recoverPassword,
        onSubmitAnimationCompleted: () {
          context.go("/Home");
        },
        loginProviders: [
          LoginProvider(
            icon: FontAwesomeIcons.google,
            label: 'Google',
            callback: () async {
              return null;
            },
          ),
          LoginProvider(
            icon: FontAwesomeIcons.apple,
            label: 'Apple',
            callback: () async {
              return null;
            },
          ),
          LoginProvider(
            icon: FontAwesomeIcons.faceAngry,
            label: 'Polito',
            callback: () async {
              debugPrint('start Polito sign in');
              await Future.delayed(loginTime);
              debugPrint('stop Polito sign in');
              return null;
            },
          ),
        ],
        termsOfService: [
          TermOfService(
            id: 'newsletter',
            mandatory: false,
            text: 'Newsletter subscription',
          ),
          TermOfService(
            id: 'general-term',
            mandatory: true,
            text: 'Term of services',
            linkUrl:
                'https://www.youtube.com/watch?v=dQw4w9WgXcQ&pp=ygUIcmlja3JvbGw%3D',
          ),
        ],
        additionalSignupFields: [
          const UserFormField(
            keyName: 'Username',
            icon: Icon(FontAwesomeIcons.userLarge),
          ),
          const UserFormField(keyName: 'Name'),
          const UserFormField(keyName: 'Surname'),
          UserFormField(
            keyName: 'phone_number',
            icon: const Icon(FontAwesomeIcons.phone),
            displayName: 'Phone Number',
            userType: LoginUserType.phone,
            fieldValidator: (value) {
              final phoneRegExp = RegExp(
                '^(\\+\\d{1,2}\\s)?\\(?\\d{3}\\)?[\\s.-]?\\d{3}[\\s.-]?\\d{4}\$',
              );
              if (value != null &&
                  value.length < 7 &&
                  !phoneRegExp.hasMatch(value)) {
                return "This isn't a valid phone number";
              }
              return null;
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
