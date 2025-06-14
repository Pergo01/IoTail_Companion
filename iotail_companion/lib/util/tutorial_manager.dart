import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Class to manage the tutorial states and user sessions for Navigation, Dog, and Reservation tutorials.
class TutorialManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  ); //// Declaring secure storage variable for persistently storing data or writing precedently stored data. This allows to persist information after the app is closed.

  // Chiavi per le varie fasi del tutorial
  static const String _navigationTutorialKey =
      'navigation_tutorial_completed'; // Key for navigation tutorial completion
  static const String _dogTutorialKey =
      'dog_tutorial_completed'; // Key for dog tutorial completion
  static const String _reservationTutorialKey =
      'reservation_tutorial_completed'; // Key for reservation tutorial completion
  static const String _lastSessionKey =
      'last_user_session'; // Key for the last user session
  static const String _firstLaunchKey =
      'app_first_launch'; // Key to check if it's the first launch of the app

  // Getters to verify if the tutorials are completed
  static Future<bool> get isNavigationTutorialCompleted async {
    try {
      final value = await _storage.read(key: _navigationTutorialKey);
      return value == 'true';
    } catch (e) {
      print('Error reading navigation tutorial: $e');
      return false;
    }
  }

  /// Checks if the dog tutorial is completed.
  static Future<bool> get isDogTutorialCompleted async {
    try {
      final value = await _storage.read(
          key: _dogTutorialKey); // Read the value for the dog tutorial key
      return value == 'true';
    } catch (e) {
      print('Error reading dog tutorial: $e');
      return false;
    }
  }

  /// Checks if the reservation tutorial is completed.
  static Future<bool> get isReservationTutorialCompleted async {
    try {
      final value = await _storage.read(
          key:
              _reservationTutorialKey); // Read the value for the reservation tutorial key
      return value == 'true';
    } catch (e) {
      print('Error reading reservation tutorial: $e');
      return false;
    }
  }

  // Methods to mark the navigation tutorial as completed
  static Future<void> markNavigationTutorialCompleted() async {
    try {
      await _storage.write(
          key: _navigationTutorialKey,
          value:
              'true'); // Write 'true' to the navigation tutorial key to mark it as completed
    } catch (e) {
      print('Error marking navigation tutorial: $e');
    }
  }

  /// Marks the dog tutorial as completed.
  static Future<void> markDogTutorialCompleted() async {
    try {
      await _storage.write(
          key: _dogTutorialKey,
          value:
              'true'); // Write 'true' to the dog tutorial key to mark it as completed
    } catch (e) {
      print('Error marking dog tutorial: $e');
    }
  }

  /// Marks the reservation tutorial as completed.
  static Future<void> markReservationTutorialCompleted() async {
    try {
      await _storage.write(
          key: _reservationTutorialKey,
          value:
              'true'); // Write 'true' to the reservation tutorial key to mark it as completed
    } catch (e) {
      print('Error marking reservation tutorial: $e');
    }
  }

  /// Determines if tutorials should be shown based on the user's session and completion status.
  static Future<bool> shouldShowTutorials({
    required String userID,
    required bool hasDogs,
    required bool hasReservations,
  }) async {
    // Check if it's a new user session
    final isNewSession = await _isNewUserSession(
        userID); // Check if the current userID is different from the last session
    if (isNewSession) {
      // If it's a new session, show tutorials based on the user's state
      await markCurrentSession(
          userID); // Mark the current session for the active user
      await _storage.delete(
          key:
              _firstLaunchKey); // Reset the first launch key since it's not the first launch anymore
      await _storage.delete(
          key: _navigationTutorialKey); // Reset the navigation tutorial key
      await _storage.delete(key: _dogTutorialKey); // Reset the dog tutorial key
      await _storage.delete(
          key: _reservationTutorialKey); // Reset the reservation tutorial key
      await _storage.delete(
          key: "userEditTutorialComplete"); // Reset the user edit tutorial key
      await _storage.delete(
          key:
              "dogEditTutorialComplete"); // Reset the user and dog edit tutorial keys
      await _storage.delete(
          key:
              "reservationTutorialComplete"); // Reset the reservation tutorial key

      return true; // Show tutorials since it's a new session
    }

    // Check if it's the first launch of the app
    final isFirstLaunch = await _isFirstAppLaunch();
    if (isFirstLaunch) {
      // If it's the first launch, show all tutorials
      await markCurrentSession(
          userID); // Mark the current session for the active user
      final navigationCompleted =
          await isNavigationTutorialCompleted; // Check if the navigation tutorial is completed
      final dogCompleted =
          await isDogTutorialCompleted; // Check if the dog tutorial is completed
      final reservationCompleted =
          await isReservationTutorialCompleted; // Check if the reservation tutorial is completed
      if (navigationCompleted && dogCompleted && reservationCompleted) {
        // If all tutorials are completed, mark the first launch as complete
        await markFirstLaunchComplete();
        return false; // Don't show any tutorials
      }
      return true; // Show tutorials since it's the first launch and not all are completed
    }

    return false; // Don't show tutorials if it's not a new session and not the first launch
  }

  /// Checks if it's the first launch of the app
  static Future<bool> _isFirstAppLaunch() async {
    final value = await _storage.read(
        key: _firstLaunchKey); // Read the value for the first launch key
    return value != 'completed';
  }

  /// Marks the first launch of the app as complete
  static Future<void> markFirstLaunchComplete() async {
    await _storage.write(
        key: _firstLaunchKey,
        value:
            'completed'); // Write 'completed' to the first launch key to mark it as complete
  }

  /// Checks if the current user session is new compared to the last session
  static Future<bool> _isNewUserSession(String userID) async {
    final lastSession = await _storage.read(
        key: _lastSessionKey); // Read the last session userID
    return lastSession != userID;
  }

  /// Marks the current user session
  static Future<void> markCurrentSession(String userID) async {
    await _storage.write(
        key: _lastSessionKey,
        value: userID); // Write the current userID to the last session key
  }

  // Method to get the current tutorial state based on user data
  static Future<TutorialState> getCurrentTutorialState({
    required String userID,
    required bool hasDogs,
    required bool hasReservations,
  }) async {
    // First, check if we should show any tutorials
    final shouldShow = await shouldShowTutorials(
      userID: userID,
      hasDogs: hasDogs,
      hasReservations: hasReservations,
    );

    if (!shouldShow) {
      return TutorialState
          .completed; // If we shouldn't show any tutorials, return completed state
    }

    // If we should show tutorials, check the completion status of each tutorial
    final navigationCompleted = await isNavigationTutorialCompleted;
    final dogCompleted = await isDogTutorialCompleted;
    final reservationCompleted = await isReservationTutorialCompleted;

    if (!navigationCompleted) {
      return TutorialState
          .navigation; // If navigation tutorial is not completed, return its state
    }

    if (hasDogs && !dogCompleted) {
      return TutorialState
          .dog; // If there are dogs and the dog tutorial is not completed, return its state
    }

    if (hasReservations && dogCompleted && !reservationCompleted) {
      return TutorialState
          .reservation; // If there are reservations, the dog tutorial is completed, and the reservation tutorial is not completed, return its state
    }

    return TutorialState
        .completed; // If all tutorials are completed, return completed state
  }

  // Methods to reset the tutorials and user session
  static Future<void> resetAllTutorials() async {
    try {
      await _storage.delete(
          key: _navigationTutorialKey); // Reset the navigation tutorial key
      await _storage.delete(key: _dogTutorialKey); // Reset the dog tutorial key
      await _storage.delete(
          key: _reservationTutorialKey); // Reset the reservation tutorial key
      await _storage.delete(key: _firstLaunchKey); // Reset the first launch key
      await _storage.delete(
          key: "dogEditTutorialComplete"); // Reset the dog edit tutorial key
      await _storage.delete(
          key: "userEditTutorialComplete"); // Reset the user edit tutorial key
      await _storage.delete(
          key:
              "reservationTutorialComplete"); // Reset the reservation tutorial key
      print('All tutorials reset');
    } catch (e) {
      print('Error resetting tutorials: $e');
    }
  }

  /// Resets the user session by deleting the last session key.
  static Future<void> resetUserSession() async {
    try {
      await _storage.delete(key: _lastSessionKey); // Reset the last session key
      print('User session reset');
    } catch (e) {
      print('Error resetting user session: $e');
    }
  }

  static String? _currentTutorialType; // Current tutorial type being handled
  static Function?
      _onTutorialCompleted; // Callback for when a tutorial is completed

  /// Sets the current tutorial type and an optional callback to be called when the tutorial is completed.
  static void setCurrentTutorial(String tutorialType, {Function? onCompleted}) {
    _currentTutorialType = tutorialType; // Set the current tutorial type
    _onTutorialCompleted = onCompleted; // Set the callback function
  }

  /// Handles the completion of the current tutorial based on its type.
  static Future<void> handleTutorialCompletion() async {
    print('Handling tutorial completion for: $_currentTutorialType');

    if (_currentTutorialType == 'navigation') {
      // Check if the current tutorial type is navigation
      await markNavigationTutorialCompleted(); // Mark the navigation tutorial as completed
    } else if (_currentTutorialType == 'dog') {
      // Check if the current tutorial type is dog
      await markDogTutorialCompleted(); // Mark the dog tutorial as completed
    } else if (_currentTutorialType == 'reservation') {
      // Check if the current tutorial type is reservation
      await markReservationTutorialCompleted(); // Mark the reservation tutorial as completed
    }

    if (_onTutorialCompleted != null) {
      // Check if the callback function is set
      _onTutorialCompleted!(); // Call the callback function if it is set
    }

    _currentTutorialType = null; // Reset the current tutorial type
    _onTutorialCompleted = null; // Reset the callback function
  }
}

/// Different states of the tutorial process.
enum TutorialState {
  navigation,
  dog,
  reservation,
  completed,
}
