import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:iotail_companion/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseApi.instance.setupFlutterNotifications();
  await FirebaseApi.instance.showNotification(message);
}

class FirebaseApi {
  FirebaseApi._();
  static final FirebaseApi instance = FirebaseApi._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false;

  Future<void> initialize() async {
    AndroidOptions _getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await requestPermission();
    await requestPermission();
    await _setupMessageHandlers();

    final token = await _messaging.getToken();
    await FlutterSecureStorage(aOptions: _getAndroidOptions())
        .write(key: "FirebaseToken", value: token);
    // print('Token: $token');
  }

  Future<void> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    print('Permission status: ${settings.authorizationStatus}');
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) {
      return;
    }

    // android setup
    const androidChannel = AndroidNotificationChannel(
        "AndroidChannel", "Android Channel",
        description: "This is the Android Channel",
        importance: Importance.high);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // ios setup
    final initializationSettingDarwin = DarwinInitializationSettings();

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingDarwin,
    );

    await _localNotifications.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {});
    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notifcation = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notifcation != null && android != null) {
      await _localNotifications.show(
          notifcation.hashCode,
          notifcation.title,
          notifcation.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              "AndroidChannel",
              "Android Channel",
              channelDescription: "This is the Android Channel",
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
                presentAlert: true, presentBadge: true, presentSound: true),
          ),
          payload: message.data.toString());
    }
  }

  Future<void> _setupMessageHandlers() async {
    // Foreground message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showNotification(message);
    });

    // Background message
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Opened app
    final _initialMessage = await _messaging.getInitialMessage();
    if (_initialMessage != null) {
      _handleBackgroundMessage(_initialMessage);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    if (message.data["type"] == "chat") {
      // Handle chat message
    } else if (message.data["type"] == "booking") {
      // Handle booking message
    }
  }
}
