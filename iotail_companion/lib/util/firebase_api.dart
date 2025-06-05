import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:iotail_companion/firebase_options.dart';

/// This is the background handler for Firebase Messaging.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase in the background
  await FirebaseApi.instance
      .setupFlutterNotifications(); // Setup local notifications
  await FirebaseApi.instance
      .showNotification(message); // Show notification for the received message
}

/// This class is a singleton that handles Firebase Messaging and local notifications.
class FirebaseApi {
  FirebaseApi._(); // Private constructor to enforce singleton pattern
  static final FirebaseApi instance = FirebaseApi._(); // Singleton instance

  final _messaging = FirebaseMessaging.instance; // Firebase Messaging instance
  final _localNotifications =
      FlutterLocalNotificationsPlugin(); // Local notifications plugin instance
  bool _isFlutterLocalNotificationsInitialized =
      false; // Flag to check if local notifications are initialized

  Future<void> initialize() async {
    AndroidOptions _getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        ); // Define Android options for secure storage
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler); // Set the background message handler
    await requestPermission(); // Request notification permissions from the user
    await _setupMessageHandlers(); // Setup message handlers for foreground and background messages

    final token = await _messaging.getToken(); // Get the Firebase token
    await FlutterSecureStorage(aOptions: _getAndroidOptions()).write(
        key: "FirebaseToken",
        value: token); // Store the firebase token in the storage
  }

  /// This method requests notification permissions from the user.
  Future<void> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    ); // Request notification permissions from the user
  }

  /// This method sets up the Flutter local notifications.
  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) {
      return; // If notifications are already initialized, return
    }

    const androidChannel = AndroidNotificationChannel(
        "AndroidChannel", "Android Channel",
        description: "This is the Android Channel",
        importance: Importance.high); // Define the Android notification channel

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
            androidChannel); // Create the Android notification channel

    const initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher'); // Initialize Android settings with the app icon

    // ios setup
    final initializationSettingDarwin =
        DarwinInitializationSettings(); // Initialize iOS settings

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingDarwin,
    ); // Combine Android and iOS settings

    await _localNotifications.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse
            details) {}); // Initialize local notifications with the settings
    _isFlutterLocalNotificationsInitialized =
        true; // Set the flag to true indicating that notifications are initialized
  }

  /// This method shows a notification with the given message.
  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notifcation =
        message.notification; // Get the notification from the message
    AndroidNotification? android = message
        .notification?.android; // Get the Android notification from the message
    if (notifcation != null && android != null) {
      // if the notification and Android notification are not null
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
          payload: message.data
              .toString()); // Show the notification with the title, body, and payload
    }
  }

  /// This method sets up message handlers for foreground and background messages.
  Future<void> _setupMessageHandlers() async {
    // Foreground message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showNotification(message);
    });

    // Background message
    // FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Opened app
    // final _initialMessage = await _messaging.getInitialMessage();
    // if (_initialMessage != null) {
    //   _handleBackgroundMessage(
    //       _initialMessage); // Handle the initial message when the app is opened from a terminated state
    // }
  }

  // void _handleBackgroundMessage(RemoteMessage message) {
  //   if (message.data["type"] == "chat") {
  //     // Handle chat message
  //   } else if (message.data["type"] == "booking") {
  //     // Handle booking message
  //   }
  // }
}
