import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TutorialManager {
  static const _storage = FlutterSecureStorage();

  // Chiavi per le varie fasi del tutorial
  static const String _navigationTutorialKey = 'navigation_tutorial_completed';
  static const String _dogTutorialKey = 'dog_tutorial_completed';
  static const String _reservationTutorialKey =
      'reservation_tutorial_completed';

  // Getters per verificare se i tutorial sono stati completati
  static Future<bool> get isNavigationTutorialCompleted async {
    final value = await _storage.read(key: _navigationTutorialKey);
    return value == 'true';
  }

  static Future<bool> get isDogTutorialCompleted async {
    final value = await _storage.read(key: _dogTutorialKey);
    return value == 'true';
  }

  static Future<bool> get isReservationTutorialCompleted async {
    final value = await _storage.read(key: _reservationTutorialKey);
    return value == 'true';
  }

  // Metodi per marcare i tutorial come completati
  static Future<void> markNavigationTutorialCompleted() async {
    await _storage.write(key: _navigationTutorialKey, value: 'true');
  }

  static Future<void> markDogTutorialCompleted() async {
    await _storage.write(key: _dogTutorialKey, value: 'true');
  }

  static Future<void> markReservationTutorialCompleted() async {
    await _storage.write(key: _reservationTutorialKey, value: 'true');
  }

  // Metodo per determinare quale tutorial mostrare
  static Future<TutorialState> getCurrentTutorialState({
    required bool hasDogs,
    required bool hasReservations,
  }) async {
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

  // Metodo per resettare tutti i tutorial (utile per test)
  static Future<void> resetAllTutorials() async {
    await _storage.delete(key: _navigationTutorialKey);
    await _storage.delete(key: _dogTutorialKey);
    await _storage.delete(key: _reservationTutorialKey);
  }

  static String? _currentTutorialType;
  static Function? _onTutorialCompleted;

  static void setCurrentTutorial(String tutorialType, {Function? onCompleted}) {
    _currentTutorialType = tutorialType;
    _onTutorialCompleted = onCompleted;
  }

  static Future<void> handleTutorialCompletion() async {
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
