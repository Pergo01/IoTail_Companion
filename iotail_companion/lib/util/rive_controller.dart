import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

class RiveAnimationControllerHelper {
  // Singleton class for managing Rive animation controllers.
  // This class ensures that only one instance is created throughout
  // the application's lifecycle, allowing easy access to animation
  // controllers across different parts of the app without the need
  // to recreate them. The Singleton pattern is used to maintain
  // consistency and avoid unnecessary resource consumption.

  static final RiveAnimationControllerHelper _instance =
      RiveAnimationControllerHelper._internal();

  factory RiveAnimationControllerHelper() {
    return _instance;
  }

  RiveAnimationControllerHelper._internal();

  Artboard? _riveArtboard;

  late RiveAnimationController _controllerIdle;
  late RiveAnimationController _controllerIdle2;
  late RiveAnimationController _controllerHandsUp;
  late RiveAnimationController _controllerHandsDown;
  late RiveAnimationController _controllerSuccess;
  late RiveAnimationController _controllerFail;
  late RiveAnimationController _controllerLookDownRight;
  late RiveAnimationController _controllerLookDownLeft;

  bool isLookingRight = false;
  bool isLookingLeft = false;

  Artboard? get riveArtboard => _riveArtboard;

  void addController(RiveAnimationController controller) {
    removeAllControllers();
    _riveArtboard?.addController(controller);
  }

  void addDownLeftController() {
    addController(_controllerLookDownLeft);
    isLookingLeft = true;
  }

  void addDownRightController() {
    addController(_controllerLookDownRight);
    isLookingRight = true;
  }

  void addFailController() => addController(_controllerFail);

  void addHandsDownController() => addController(_controllerHandsDown);

  void addHandsUpController() => addController(_controllerHandsUp);

  void addSuccessController() => addController(_controllerSuccess);

  void addIdle2Controller() => addController(_controllerIdle2);

  void playSequentialAnimationControllers(List<void Function()> methods) {
    if (methods.isEmpty) return;

    void playNext(int index) {
      if (index >= methods.length) return;

      // Esegui il metodo attuale
      methods[index]();

      // Trova il controller attivo aggiunto da quel metodo
      RiveAnimationController? currentController;
      if (methods[index] == addHandsDownController) {
        currentController = _controllerHandsDown;
      } else if (methods[index] == addFailController) {
        currentController = _controllerFail;
      } else if (methods[index] == addIdle2Controller) {
        currentController = _controllerIdle2;
      } else if (methods[index] == addDownLeftController) {
        currentController = _controllerLookDownLeft;
      }
      // Aggiungi altri casi se necessario

      if (currentController is SimpleAnimation) {
        currentController.isActiveChanged.addListener(() {
          if (currentController != null && !currentController.isActive) {
            playNext(index + 1); // Passa al prossimo metodo
          }
        });
      } else {
        // Se il controller non è SimpleAnimation, vai al prossimo
        playNext(index + 1);
      }
    }

    playNext(0);
  }

  Future<void> loadRiveFile(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final file = RiveFile.import(data);
    _riveArtboard = file.mainArtboard;

    _controllerIdle = SimpleAnimation('idle_look_around');
    _controllerIdle2 = SimpleAnimation('idle');
    _controllerHandsUp = SimpleAnimation('eye_cover');
    _controllerHandsDown = SimpleAnimation('eye_uncover');
    _controllerSuccess = SimpleAnimation('success');
    _controllerFail = SimpleAnimation('fail');
    _controllerLookDownRight = SimpleAnimation('look_right');
    _controllerLookDownLeft = SimpleAnimation('look_left');

    _riveArtboard?.addController(_controllerIdle);
  }

  void removeAllControllers() {
    final listOfControllers = [
      _controllerIdle,
      _controllerIdle2,
      _controllerHandsUp,
      _controllerHandsDown,
      _controllerSuccess,
      _controllerFail,
      _controllerLookDownRight,
      _controllerLookDownLeft,
    ];
    for (var controller in listOfControllers) {
      _riveArtboard?.removeController(controller);
    }
    isLookingLeft = false;
    isLookingRight = false;
  }

  void dispose() {
    removeAllControllers();
    _controllerIdle.dispose();
    _controllerIdle2.dispose();
    _controllerHandsUp.dispose();
    _controllerHandsDown.dispose();
    _controllerSuccess.dispose();
    _controllerFail.dispose();
    _controllerLookDownRight.dispose();
    _controllerLookDownLeft.dispose();
  }
}
