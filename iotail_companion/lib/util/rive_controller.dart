import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

/// A singleton class to manage Rive animation controllers for a Rive animation.
class RiveAnimationControllerHelper {
  // Singleton class for managing Rive animation controllers.
  // This class ensures that only one instance is created throughout
  // the application's lifecycle, allowing easy access to animation
  // controllers across different parts of the app without the need
  // to recreate them. The Singleton pattern is used to maintain
  // consistency and avoid unnecessary resource consumption.

  static final RiveAnimationControllerHelper _instance =
      RiveAnimationControllerHelper
          ._internal(); // Private constructor for singleton

  /// Factory constructor to return the singleton instance.
  factory RiveAnimationControllerHelper() {
    return _instance;
  }

  RiveAnimationControllerHelper._internal(); // Private constructor

  Artboard? _riveArtboard; // The Rive artboard that contains the animations

  late RiveAnimationController _controllerIdle; // Controllers idle animation
  late RiveAnimationController
      _controllerIdle2; // Controller for a second idle animation
  late RiveAnimationController
      _controllerHandsUp; // Controller for hands up animation
  late RiveAnimationController
      _controllerHandsDown; // Controller for hands down animation
  late RiveAnimationController
      _controllerSuccess; // Controller for success animation
  late RiveAnimationController _controllerFail; // Controller for fail animation
  late RiveAnimationController
      _controllerLookDownRight; // Controller for looking down right animation
  late RiveAnimationController
      _controllerLookDownLeft; // Controller for looking down left animation
  late RiveAnimationController
      _controllerSuccessToIdle; // Controller for transitioning from success to idle animation

  bool isLookingRight =
      false; // Flag to check if the character is looking right
  bool isLookingLeft = false; // Flag to check if the character is looking left

  Artboard? get riveArtboard => _riveArtboard; // Getter for the Rive artboard

  /// Adds a Rive animation controller to the artboard, removing any existing controllers.
  void addController(RiveAnimationController controller) {
    removeAllControllers();
    _riveArtboard?.addController(controller);
  }

  /// Adds a controller for looking down left animation.
  void addDownLeftController() {
    addController(_controllerLookDownLeft);
    isLookingLeft = true;
  }

  /// Adds a controller for looking down right animation.
  void addDownRightController() {
    addController(_controllerLookDownRight);
    isLookingRight = true;
  }

  /// Adds a controller for looking down left animation.
  void addFailController() => addController(_controllerFail);

  /// Adds a controller for hands down animation.
  void addHandsDownController() => addController(_controllerHandsDown);

  /// Adds a controller for hands up animation.
  void addHandsUpController() => addController(_controllerHandsUp);

  /// Adds a controller for success animation.
  void addSuccessController() => addController(_controllerSuccess);

  /// Adds a controller for the second idle animation.
  void addIdle2Controller() => addController(_controllerIdle2);

  /// Adds a controller for transitioning from success to idle animation.
  void addSuccessToIdleController() => addController(_controllerSuccessToIdle);

  /// Adds a controller for the idle animation.
  void addIdleController() => addController(_controllerIdle);

  /// Plays a sequence of animation controllers in order.
  void playSequentialAnimationControllers(List<void Function()> methods) {
    if (methods.isEmpty) return; // if no methods are provided, do nothing

    // Recursive function to play each method in the list
    void playNext(int index) {
      if (index >= methods.length)
        return; // Base case: if index is out of bounds, stop recursion

      // Execute the current method
      methods[index]();

      // Find the current controller based on the method
      RiveAnimationController? currentController;
      if (methods[index] == addHandsDownController) {
        currentController = _controllerHandsDown;
      } else if (methods[index] == addFailController) {
        currentController = _controllerFail;
      } else if (methods[index] == addIdle2Controller) {
        currentController = _controllerIdle2;
      } else if (methods[index] == addDownLeftController) {
        currentController = _controllerLookDownLeft;
      } else if (methods[index] == addSuccessToIdleController) {
        currentController = _controllerSuccessToIdle;
      } else if (methods[index] == addIdleController) {
        currentController = _controllerIdle;
      }
      // Add more conditions here for other methods if needed

      if (currentController is SimpleAnimation) {
        // If the controller is a SimpleAnimation
        currentController.isActiveChanged.addListener(() {
          if (currentController != null && !currentController.isActive) {
            playNext(index + 1); // Passa al prossimo metodo
          } // If the current controller is no longer active, play the next method
        }); // Listen for when the current controller is no longer active
      } else {
        // If the controller is not a SimpleAnimation, just play the next method
        playNext(index + 1);
      }
    }

    playNext(0); // Start the recursive function with the first method
  }

  /// Loads a Rive file from the specified asset path.
  Future<void> loadRiveFile(String assetPath) async {
    final data = await rootBundle
        .load(assetPath); // Load the Rive file from the asset bundle
    final file = RiveFile.import(data); // Import the Rive file data
    _riveArtboard =
        file.mainArtboard; // Get the main artboard from the Rive file

    _controllerIdle = SimpleAnimation(
        'idle_look_around'); // Initialize the idle animation controller
    _controllerIdle2 = SimpleAnimation(
        'idle'); // Initialize the second idle animation controller
    _controllerHandsUp = SimpleAnimation(
        'eye_cover'); // Initialize the hands up animation controller
    _controllerHandsDown = SimpleAnimation(
        'eye_uncover'); // Initialize the hands down animation controller
    _controllerSuccess = SimpleAnimation(
        'success'); // Initialize the success animation controller
    _controllerFail =
        SimpleAnimation('fail'); // Initialize the fail animation controller
    _controllerLookDownRight = SimpleAnimation(
        'look_right'); // Initialize the looking down right animation controller
    _controllerLookDownLeft = SimpleAnimation(
        'look_left'); // Initialize the looking down left animation controller
    _controllerSuccessToIdle = SimpleAnimation(
        'success_to_idle'); // Initialize the success to idle animation controller

    _riveArtboard?.addController(
        _controllerIdle); // Add the idle animation controller to the artboard
  }

  /// Removes all animation controllers from the Rive artboard.
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
      _controllerSuccessToIdle
    ];
    for (var controller in listOfControllers) {
      _riveArtboard?.removeController(controller);
    } // Remove all controllers from the artboard
    isLookingLeft = false; // Reset the looking left flag
    isLookingRight = false; // Reset the looking right flag
  }

  void dispose() {
    removeAllControllers();
    _controllerIdle.dispose(); // Dispose of the idle animation controller
    _controllerIdle2
        .dispose(); // Dispose of the second idle animation controller
    _controllerHandsUp
        .dispose(); // Dispose of the hands up animation controller
    _controllerHandsDown
        .dispose(); // Dispose of the hands down animation controller
    _controllerSuccess.dispose(); // Dispose of the success animation controller
    _controllerFail.dispose(); // Dispose of the fail animation controller
    _controllerLookDownRight
        .dispose(); // Dispose of the looking down right animation controller
    _controllerLookDownLeft
        .dispose(); // Dispose of the looking down left animation controller
    _controllerSuccessToIdle
        .dispose(); // Dispose of the success to idle animation controller
  }
}
