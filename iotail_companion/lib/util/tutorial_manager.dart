import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TutorialManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Chiavi per le varie fasi del tutorial
  static const String _navigationTutorialKey = 'navigation_tutorial_completed';
  static const String _dogTutorialKey = 'dog_tutorial_completed';
  static const String _reservationTutorialKey =
      'reservation_tutorial_completed';
  static const String _lastSessionKey = 'last_user_session';
  static const String _firstLaunchKey = 'app_first_launch';

  // Getters per verificare se i tutorial sono stati completati
  static Future<bool> get isNavigationTutorialCompleted async {
    try {
      final value = await _storage.read(key: _navigationTutorialKey);
      return value == 'true';
    } catch (e) {
      print('Error reading navigation tutorial: $e');
      return false;
    }
  }

  static Future<bool> get isDogTutorialCompleted async {
    try {
      final value = await _storage.read(key: _dogTutorialKey);
      return value == 'true';
    } catch (e) {
      print('Error reading dog tutorial: $e');
      return false;
    }
  }

  static Future<bool> get isReservationTutorialCompleted async {
    try {
      final value = await _storage.read(key: _reservationTutorialKey);
      return value == 'true';
    } catch (e) {
      print('Error reading reservation tutorial: $e');
      return false;
    }
  }

  // Metodi per marcare i tutorial come completati - ORA SONO ASYNC
  static Future<void> markNavigationTutorialCompleted() async {
    try {
      await _storage.write(key: _navigationTutorialKey, value: 'true');
    } catch (e) {
      print('Error marking navigation tutorial: $e');
    }
  }

  static Future<void> markDogTutorialCompleted() async {
    try {
      await _storage.write(key: _dogTutorialKey, value: 'true');
    } catch (e) {
      print('Error marking dog tutorial: $e');
    }
  }

  static Future<void> markReservationTutorialCompleted() async {
    try {
      await _storage.write(key: _reservationTutorialKey, value: 'true');
    } catch (e) {
      print('Error marking reservation tutorial: $e');
    }
  }

  static Future<bool> shouldShowTutorials({
    required String userID,
    required bool hasDogs,
    required bool hasReservations,
  }) async {
    // Controlla se è il primo avvio dell'app
    final isFirstLaunch = await _isFirstAppLaunch();
    if (isFirstLaunch) {
      await _markCurrentSession(userID);
      final navigationCompleted = await isNavigationTutorialCompleted;
      final dogCompleted = await isDogTutorialCompleted;
      final reservationCompleted = await isReservationTutorialCompleted;
      if (navigationCompleted && dogCompleted && reservationCompleted) {
        await _markFirstLaunchComplete();
        return false; // Non mostrare i tutorial se sono già stati completati
      }
      return true;
    }

    // Controlla se è una nuova sessione utente
    final isNewSession = await _isNewUserSession(userID);
    if (isNewSession) {
      await _markCurrentSession(userID);
      await _storage.delete(key: _firstLaunchKey);
      await _storage.delete(key: _navigationTutorialKey);
      await _storage.delete(key: _dogTutorialKey);
      await _storage.delete(key: _reservationTutorialKey);

      // Anche se è una nuova sessione, controlla se ci sono tutorial ancora da completare
      final navigationCompleted = await isNavigationTutorialCompleted;
      final dogCompleted = await isDogTutorialCompleted;
      final reservationCompleted = await isReservationTutorialCompleted;

      // Mostra i tutorial solo se ce ne sono ancora da completare
      if (!navigationCompleted) {
        return true;
      }

      if (hasDogs && !dogCompleted) {
        return true;
      }

      if (hasReservations && dogCompleted && !reservationCompleted) {
        return true;
      }
    }

    return false;
  }

  static Future<bool> _isFirstAppLaunch() async {
    final value = await _storage.read(key: _firstLaunchKey);
    return value != 'completed';
  }

  static Future<void> _markFirstLaunchComplete() async {
    await _storage.write(key: _firstLaunchKey, value: 'completed');
  }

  static Future<bool> _isNewUserSession(String userID) async {
    final lastSession = await _storage.read(key: _lastSessionKey);
    return lastSession != userID;
  }

  static Future<void> _markCurrentSession(String userID) async {
    await _storage.write(key: _lastSessionKey, value: userID);
  }

  // Metodo per determinare quale tutorial mostrare
  static Future<TutorialState> getCurrentTutorialState({
    required String userID,
    required bool hasDogs,
    required bool hasReservations,
  }) async {
    // Prima controlla se dovremmo mostrare i tutorial
    final shouldShow = await shouldShowTutorials(
      userID: userID,
      hasDogs: hasDogs,
      hasReservations: hasReservations,
    );

    if (!shouldShow) {
      return TutorialState.completed;
    }

    // Se dovremmo mostrarli, determina quale tutorial mostrare
    final navigationCompleted = await isNavigationTutorialCompleted;
    final dogCompleted = await isDogTutorialCompleted;
    final reservationCompleted = await isReservationTutorialCompleted;

    if (!navigationCompleted) {
      return TutorialState.navigation;
    }

    if (hasDogs && !dogCompleted) {
      return TutorialState.dog;
    }

    if (hasReservations && dogCompleted && !reservationCompleted) {
      return TutorialState.reservation;
    }

    return TutorialState.completed;
  }

  // Metodo per resettare tutti i tutorial (utile per test) - ORA ASYNC
  static Future<void> resetAllTutorials() async {
    try {
      await _storage.delete(key: _navigationTutorialKey);
      await _storage.delete(key: _dogTutorialKey);
      await _storage.delete(key: _reservationTutorialKey);
      await _storage.delete(key: _firstLaunchKey);
      await _storage.delete(key: "dogEditTutorialComplete");
      await _storage.delete(key: "userEditTutorialComplete");
      print('All tutorials reset');
    } catch (e) {
      print('Error resetting tutorials: $e');
    }
  }

  static Future<void> resetUserSession() async {
    try {
      await _storage.delete(key: _lastSessionKey);
      print('User session reset');
    } catch (e) {
      print('Error resetting user session: $e');
    }
  }

  static String? _currentTutorialType;
  static Function? _onTutorialCompleted;

  static void setCurrentTutorial(String tutorialType, {Function? onCompleted}) {
    _currentTutorialType = tutorialType;
    _onTutorialCompleted = onCompleted;
  }

  static Future<void> handleTutorialCompletion() async {
    print('Handling tutorial completion for: $_currentTutorialType');

    if (_currentTutorialType == 'navigation') {
      await markNavigationTutorialCompleted();
    } else if (_currentTutorialType == 'dog') {
      await markDogTutorialCompleted();
    } else if (_currentTutorialType == 'reservation') {
      await markReservationTutorialCompleted();
    }

    // Chiama il callback se presente
    if (_onTutorialCompleted != null) {
      _onTutorialCompleted!();
    }

    _currentTutorialType = null;
    _onTutorialCompleted = null;
  }
}

enum TutorialState {
  navigation,
  dog,
  reservation,
  completed,
}
