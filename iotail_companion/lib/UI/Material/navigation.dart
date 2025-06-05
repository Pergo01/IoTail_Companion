import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:iotail_companion/util/dataMarker.dart';
import 'package:iotail_companion/util/store.dart';
import 'package:iotail_companion/UI/Material/home.dart';
import 'package:iotail_companion/UI/Material/map.dart';
import 'package:iotail_companion/util/requests.dart' as requests;
import 'package:iotail_companion/util/user.dart';
import 'package:iotail_companion/util/dog.dart';
import 'package:iotail_companion/util/breed.dart';
import 'package:iotail_companion/util/reservation.dart';
import 'package:iotail_companion/util/tutorial_manager.dart';
import 'package:iotail_companion/util/tutorial_keys.dart';

class Navigation extends StatefulWidget {
  final String? ip; // IP address of the server
  final String? token; // Authentication token
  final String? userID; // User ID

  const Navigation(
      {super.key, required this.ip, required this.token, required this.userID});

  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> with TickerProviderStateMixin {
  static const Duration duration = Duration(milliseconds: 300);
  late final AnimationController
      controller; // Animation controller for the home page <--> map transition
  late final AnimationController
      animateMenuController; // Animation controller for the menu transition
  late final MenuController menuController =
      MenuController(); // Menu controller for the popup menu button in the bottom navigation bar
  late ScrollController
      _scrollController; // Scroll controller for the dog selection list
  int currentPageIndex = 0; // Current page index for the home page and map page
  int selectedDog = 0; // Index of the selected dog in the dog selection list
  bool isOpen = false; // Whether the popup menu button is open or not
  late List<Uint8List?>
      dogPicture; // List of dog pictures for the dog selection list
  late DataMarker selectedShop; // Currently selected shop marker on the map
  late List<DataMarker> markersList; // List of markers for the map

  late Future<User> user; // Future for the user data
  late Future<List<Store>> stores; // Future for the list of stores
  late Future<List<Reservation>>
      prenotazioni; // Future for the list of reservations
  late Future<List<Breed>> breeds; // Future for the list of breeds
  late Future<MqttServerClient> MQTTClient; // Future for the MQTT client

  TutorialState _currentTutorialState =
      TutorialState.completed; // Current state of the tutorial
  bool _tutorialCheckDone =
      false; // Flag to check if the tutorial check has been done

  /// Get the user data from the server
  Future<User> getUser() async {
    final Map<String, dynamic> data = await requests.getUser(
        widget.ip!, widget.userID!, widget.token!); // Fetch user data
    final Uint8List? profilePicture = await requests.getProfilePicture(
        widget.ip!, widget.userID!, widget.token!); // Fetch profile picture
    data["ProfilePicture"] = profilePicture; // Add profile picture to user data
    for (Map dog in data["Dogs"]) {
      // Iterate through each dog
      Uint8List? picture = await requests.getDogPicture(widget.ip!,
          widget.userID!, dog["DogID"], widget.token!); // Fetch dog picture
      dog["Picture"] = picture; // Add dog picture to dog data
    }
    User user = User.fromJson(data); // Create User object from data
    if (selectedDog >= user.dogs.length) {
      // Check if the selected dog index is valid
      selectedDog = 0; // Reset to the first dog if not valid
    }
    return user;
  }

  /// Get the list of reservations for the user
  Future<List<Reservation>> getReservations() async {
    var data = await requests.getReservations(
        widget.ip!, widget.userID!, widget.token!); // Fetch reservations data
    return data
        .map((reservation) => Reservation.fromJson(reservation))
        .toList(); // Create a list of Reservation objects from the data
  }

  /// Get the list of stores from the server
  Future<List<Store>> getStores() async {
    var data = await requests.getStores(
        widget.ip!, widget.token!); // Fetch stores data
    List<Store> tmp = []; // Temporary list to hold Store objects
    for (var store in data) {
      // Iterate through each store
      tmp.add(Store.fromJson(store)); // Create Store object from data
    }
    return tmp; // Return the list of Store objects
  }

  /// Reserve a kennel for a dog
  Future<String> reserveKennel(Map<String, dynamic> data) async {
    final Map response = await requests.reserve(
        widget.ip!, widget.token!, data); // Send reservation request
    if (response["message"].contains("Failed")) {
      return response["message"]; // Return error message if reservation failed
    } else {
      setState(() {
        prenotazioni = getReservations(); // Refresh reservations
      });
      return "Reservation was successful"; // Return success message if reservation was successful
    }
  }

  /// Unlock a kennel for a dog
  Future<String> unlockKennel(Map<String, dynamic> data) async {
    final Map response = await requests.unlock_kennel(
        widget.ip!, widget.token!, data); // Send unlock request
    if (response["message"].contains("Failed")) {
      return response["message"]; // Return error message if unlock failed
    } else if (response["message"].contains("Kennel")) {
      return response[
          "message"]; // Return message if kennel is already unlocked
    } else {
      setState(() {
        prenotazioni = getReservations(); // Refresh reservations
      });
      return "Kennel was unlocked"; // Return success message if unlock was successful
    }
  }

  /// Get the list of breeds from the server
  Future<List<Breed>> getBreeds() async {
    var data = await requests.getBreeds(
        widget.ip!, widget.token!); // Fetch breeds data
    List<Breed> tmp = []; // Temporary list to hold Breed objects
    for (var breed in data) {
      // Iterate through each breed
      tmp.add(Breed.fromJson(breed)); // Create Breed object from data
    }
    return tmp; // Return the list of Breed objects
  }

  /// Initialize the MQTT client
  Future<MqttServerClient> initializeClient() async {
    final MqttServerClient client = MqttServerClient(
        widget.ip!, widget.userID!); // Create a new MQTT client
    client.logging(on: false); // Disable logging for the client
    client.keepAlivePeriod = 20; // Set keep alive period to 20 seconds
    client.onDisconnected = onDisconnected; // Set the disconnect callback
    final connMess = MqttConnectMessage()
        .withClientIdentifier(widget.userID!)
        .startClean(); // Non persistent session
    client.connectionMessage = connMess; // Set the connection message
    try {
      await client.connect(); // Attempt to connect to the MQTT broker
    } on Exception catch (e) {
      print('Client exception - $e');
      client.disconnect(); // Disconnect the client if an exception occurs
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      // Check if the client is connected
      print('Mosquitto client connected');
    } else {
      print(
          'ERROR Mosquitto client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
      client.disconnect(); // Disconnect the client if connection failed
    }

    return client; // Return the initialized MQTT client
  }

  /// MQTT client disconnect callback
  void onDisconnected() {
    print('Client disconnection');
  }

  @override
  void initState() {
    super.initState();
    user = getUser(); // Initialize the user data
    breeds = getBreeds(); // Initialize the list of breeds
    prenotazioni = getReservations(); // Initialize the list of reservations
    stores = getStores(); // Initialize the list of stores
    MQTTClient = initializeClient(); // Initialize the MQTT client
    _scrollController = ScrollController(); // Initialize the scroll controller
    controller = AnimationController(
      duration: duration,
      vsync: this,
    ); // Animation controller for the home page <--> map transition
    animateMenuController = AnimationController(
      duration: duration,
      vsync: this,
      value: 0.0,
    )..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.dismissed) {
          // The moment the menu is closed, it will no longer be on the screen or animatable.
          // To allow for a closing animation, we wait until our closing animation is finished before
          // we close the menu anchor.
          menuController.close();
        } else if (!menuController.isOpen) {
          // The menu should be open while the animation status is forward, completed, or reverse
          menuController.open();
        }
      });
    _checkAndShowTutorial(); // Check and show the tutorial if needed
  }

  void _showDogTutorial() {
    TutorialManager.setCurrentTutorial('dog', onCompleted: () {
      _checkNextTutorial(); // Check for the next tutorial state after completing the dog tutorial
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait for the widget to be initialized
      ShowCaseWidget.of(context).startShowCase([
        dogCardKey,
      ]); // Start the showcase for the dog card
    });
  }

  /// Check and show the tutorial based on the user's state
  Future<void> _checkAndShowTutorial() async {
    if (!_tutorialCheckDone) {
      // Check if the tutorial has already been checked
      _tutorialCheckDone = true; // Set the flag to true to avoid checking again

      final user = await this.user; // Get the user data
      final reservations = await prenotazioni; // Get the list of reservations

      _currentTutorialState = await TutorialManager.getCurrentTutorialState(
        userID: widget.userID!,
        hasDogs: user.dogs.isNotEmpty,
        hasReservations: reservations.isNotEmpty,
      ); // Get the current tutorial state based on the user's data and last shown tutorial

      if (_currentTutorialState == TutorialState.navigation) {
        _showNavigationTutorial(); // Show the navigation tutorial if the current state is navigation
      } else if (_currentTutorialState == TutorialState.dog) {
        _showDogTutorial(); // Show the dog tutorial if the current state is dog
      } else if (_currentTutorialState == TutorialState.reservation) {
        _showReservationTutorial(); // Show the reservation tutorial if the current state is reservation
      }
    }
  }

  /// Show the navigation tutorial
  void _showNavigationTutorial() {
    TutorialManager.setCurrentTutorial('navigation', onCompleted: () {
      _checkNextTutorial(); // Check for the next tutorial state after completing the navigation tutorial
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait for the widget to be initialized
      ShowCaseWidget.of(context).startShowCase([
        homePageKey,
        menuNavBarButtonKey,
        userEditButtonKey,
        unlockKennelFABKey,
        mapNavBarButtonKey,
        mapPageKey,
        homePageNavBarButtonKey
      ]); // Start the showcase for the navigation tutorial
    });
  }

  /// Show the reservation tutorial
  void _showReservationTutorial() {
    TutorialManager.setCurrentTutorial('reservation', onCompleted: () {
      _checkNextTutorial(); // Check for the next tutorial state after completing the reservation tutorial
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait for the widget to be initialized
      ShowCaseWidget.of(context).startShowCase([
        reservationCardKey,
      ]); // Start the showcase for the reservation tutorial
    });
  }

  /// Check the next tutorial state and show the appropriate tutorial
  void _checkNextTutorial() async {
    final user = await this.user; // Get the user data
    final reservations = await prenotazioni; // Get the list of reservations

    final nextState = await TutorialManager.getCurrentTutorialState(
      userID: widget.userID!,
      hasDogs: user.dogs.isNotEmpty,
      hasReservations: reservations.isNotEmpty,
    ); // Get the next tutorial state based on the user's data and last shown tutorial

    if (nextState != _currentTutorialState &&
        nextState != TutorialState.completed) {
      _currentTutorialState =
          nextState; // Update the current tutorial state is the next state is different and the tutorial is not completed

      if (_currentTutorialState == TutorialState.dog) {
        _showDogTutorial(); // Show the dog tutorial if the next state is dog
      } else if (_currentTutorialState == TutorialState.reservation) {
        if (currentPageIndex == 1) {
          // If the current page is the map page, reverse the animation to go back to the home page
          setState(() {
            controller.reverse().then((_) {
              // Reverse the animation to go back to the home page
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Wait for the widget to be initialized
                _showReservationTutorial(); // Show the reservation tutorial
              });
            });
            currentPageIndex = 0; // Update the current page index to home page
          });
        } else {
          _showReservationTutorial(); // Show the reservation tutorial if the current page is home page
        }
      }
    }
  }

  @override
  void dispose() {
    MQTTClient.then((val) => val.disconnect()); // Disconnect the MQTT client
    controller
        .dispose(); // Dispose the home page <--> map transition animation controller
    animateMenuController
        .dispose(); // Dispose the menu transition animation controller
    super.dispose();
  }

  /// Scroll to the selected dog in the dog selection list
  void _scrollToSelectedDog(int index) {
    _scrollController.animateTo(
      index * 342, // Adjust the value based on the width of each tile
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ); // Animate the scroll to the selected dog
  }

  /// Check if a store has a suitable kennel
  bool _isStoreSuitable(Store store, Dog dog, List<Reservation> reservations) {
    List<int?> storeIDs = reservations.map((reservation) {
      if (reservation.dogID == dog.dogID) {
        return reservation
            .storeID; // Get the store ID from the reservation if it matches the dog's ID
      }
    }).toList(); // Create a list of store IDs from the reservations for the selected dog
    if (storeIDs.contains(store.id)) {
      return false; // If the store ID is already reserved for the dog, return false
    }
    for (var kennel in store.kennels) {
      if (!kennel.booked &&
          !kennel.occupied &&
          _sizeFits(kennel.size, dog.size)) {
        return true; // If there is a kennel that is not booked or occupied and fits the dog's size, return true
      }
    }
    return false; // If no suitable kennel is found, return false
  }

  /// Check if the kennel size fits the dog size
  bool _sizeFits(String kennelSize, String dogSize) {
    const sizeOrder = {
      "Small": 0,
      "Medium": 1,
      "Large": 2
    }; // Define the size order for comparison
    return sizeOrder[kennelSize]! >=
        sizeOrder[
            dogSize]!; // Check if the kennel size is greater than or equal to the dog size
  }

  /// Get the list of markers for the map based on the user's dogs and reservations
  List<DataMarker> _getMarkersList(
      List<Store> stores, User user, List<Reservation> reservations) {
    List<DataMarker> markersList;
    if (user.dogs.isEmpty) {
      // If the user has no dogs, show all stores
      dogPicture = [];
      markersList = (stores).map(
        (store) {
          Color color;
          bool isSuitable = true;
          color = Theme.of(context).colorScheme.primary;
          return DataMarker(
              id: store.id,
              name: store.name,
              isSuitable: isSuitable,
              height: 30,
              width: 30,
              point: store.location,
              child: Icon(
                Icons.pets,
                color: color,
              ));
        },
      ).toList(); // Create markers for all stores
    } else {
      // If the user has dogs, mark unsuitable stores in red and set them as unavailable
      dogPicture = user.dogs
          .map((dog) => dog.picture)
          .toList(); // Get the pictures of the user's dogs
      Dog dog = user.dogs[selectedDog]; // Get the selected dog
      markersList = stores.map(
        (store) {
          Color color;
          bool isSuitable = _isStoreSuitable(store, dog, reservations);
          if (isSuitable) {
            color = Theme.of(context).colorScheme.primary;
          } else {
            color = Colors.red;
          }
          return DataMarker(
            id: store.id,
            name: store.name,
            isSuitable: isSuitable,
            height: 30,
            width: 30,
            point: store.location,
            child: Icon(
              Icons.pets,
              color: color,
            ),
          );
        },
      ).toList(); // Create markers for stores based on the suitability for the selected dog
    }
    return markersList; // Return the list of markers
  }

  /// Show the dialog to reserve a kennel for a dog
  void _showUnlockKennelDialog(BuildContext context, User user,
      List<Store> storesList, List<Reservation> reservations) {
    showDialog(
        context: context,
        builder: (dialogContext) {
          final TextEditingController idController = TextEditingController();
          final TextEditingController codeController = TextEditingController();
          int kennelID = -1;
          int unlockCode = -1;
          return AlertDialog(
            actionsAlignment: MainAxisAlignment.spaceAround,
            title: const Text("Unlock Kennel"),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              // Text field for kennel ID
              TextField(
                keyboardType: TextInputType.number,
                controller: idController,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    kennelID = int.parse(value);
                  }
                },
                decoration: InputDecoration(
                    labelText: "Kennel ID",
                    helperText: "ID of the kennel you want to unlock",
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    helperStyle: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 9)),
              ),
              SizedBox(
                height: 10,
              ), // Spacing between text fields
              // Text field for unlock code
              TextField(
                keyboardType:
                    TextInputType.number, // Keyboard type for numeric input
                controller: codeController,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    unlockCode = int.parse(value);
                  }
                },
                decoration: InputDecoration(
                    labelText: "Kennel Code",
                    helperText: "Unlock code of the kennel you want to unlock",
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    helperStyle: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 9)),
              ),
            ]),
            actions: [
              // Button to unlock the kennel
              TextButton(
                  onPressed: () async {
                    if (kennelID == -1 || unlockCode == -1) {
                      // Check if at least one of the fields is not filled
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Please fill all fields"),
                          duration: const Duration(seconds: 3),
                        ),
                      ); // Show a snackbar if the fields are not filled
                      context.pop(); // Close the dialog
                      return; // Exit the function
                    }
                    Map<String, dynamic> data = {
                      "dogID": user.dogs[selectedDog].dogID,
                      "userID": widget.userID,
                      "dog_size": user.dogs[selectedDog].size,
                      "kennelID": kennelID,
                      "unlockCode": unlockCode,
                    }; // Prepare the data for the unlock request
                    final response = await unlockKennel(
                        data); // Call the unlock kennel function with the prepared data
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response),
                        duration: const Duration(seconds: 3),
                      ),
                    ); // Show a snackbar with the response from the unlock request
                    setState(() {
                      prenotazioni =
                          getReservations(); // Refresh the reservations
                      stores = getStores(); // Refresh the stores
                      markersList = _getMarkersList(storesList, user,
                          reservations); // Refresh the markers list
                    });
                    _checkNextTutorial(); // Check for the next tutorial state
                    context.pop(); // Close the dialog
                  },
                  child: Text("Unlock")),
              // Button to close the dialog without unlocking
              TextButton(onPressed: () => context.pop(), child: Text("Cancel"))
            ],
          );
        });
  }

  /// Reset all tutorials and show the navigation tutorial again
  Future<void> _resetTutorials() async {
    await TutorialManager.resetAllTutorials();
    _tutorialCheckDone = false;
    _checkAndShowTutorial();
  }

  @override
  Widget build(BuildContext context) {
    double width =
        MediaQuery.of(context).size.width; // Get the width of the screen
    double height =
        MediaQuery.of(context).size.height; // Get the height of the screen
    return FutureBuilder(
      future: Future.wait([
        user,
        prenotazioni,
        stores,
        breeds,
        MQTTClient
      ]), // Wait for all the data to be fetched or initialized
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // if the snapshot has data (successfully fetched)
          dogPicture = []; // Initialize the dogPicture list
          markersList = _getMarkersList(
              snapshot.data![2] as List<Store>,
              snapshot.data![0] as User,
              snapshot.data![1] as List<
                  Reservation>); // Get the markers list based on the fetched data
          return Scaffold(
            extendBody: true,
            appBar: AppBar(
              centerTitle: true,
              forceMaterialTransparency: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.inversePrimary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(
                    bounds), // Gradient for the title text from top left to bottom right
                child: const Text(
                  'IoTail',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              actions: [
                // Button to reset tutorials
                IconButton(
                    onPressed: _resetTutorials,
                    icon: Icon(Icons.help_outline),
                    color: Theme.of(context).colorScheme.onSurface),
                // Button to open the user profile edit page
                Showcase(
                  key: userEditButtonKey,
                  titleAlignment: Alignment.centerLeft,
                  title: "Edit profile",
                  titleTextStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  descriptionAlignment: Alignment.centerLeft,
                  description: "From this button, you can edit your profile",
                  descTextStyle: Theme.of(context).textTheme.bodyMedium,
                  tooltipBackgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  targetBorderRadius: BorderRadius.circular(30),
                  child: IconButton(
                      onPressed: () {
                        context.push("/User", extra: {
                          "user": snapshot.data![
                              0], // Pass the user data to the user profile edit page
                          "ip": widget.ip,
                          "token": widget.token,
                          "onEdit": () async {
                            setState(() {
                              user = getUser(); // Refresh the user data
                            });
                          }
                        }); // Navigate to the user profile edit page
                      },
                      icon: ((snapshot.data![0] as User)
                                  .profilePicture!
                                  .isEmpty) ||
                              (snapshot.data![0] as User).profilePicture == null
                          ? Icon(Icons.account_circle_outlined,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface) // Default icon if no profile picture is set
                          : Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundImage: Image.memory(
                                        (snapshot.data![0] as User)
                                            .profilePicture!)
                                    .image,
                              ), // Circle avatar with the user's profile picture if available
                            )),
                ),
              ],
            ),
            // Build the navigation bar as a pill at the bottom of the screen
            bottomNavigationBar: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(minWidth: 172, maxHeight: 100),
                child: Card(
                  margin: defaultTargetPlatform == TargetPlatform.iOS
                      ? EdgeInsets.only(
                          bottom: height / 30,
                          left: width / 4 + 12,
                          right: width / 4 + 12) // iOS specific margin
                      : EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal:
                              width / 4 + 12), // Android specific margin
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.primary)),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 172),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Home screen button
                        Showcase(
                          key: homePageNavBarButtonKey,
                          disableBarrierInteraction: true,
                          titleAlignment: Alignment.centerLeft,
                          title: "Home screen",
                          titleTextStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          descriptionAlignment: Alignment.centerLeft,
                          description: (snapshot.data![0] as User)
                                  .dogs
                                  .isEmpty // Display a different message if the user has no dogs
                              ? "Now, let's go back to the home screen. It's time to add your first dog."
                              : "Now, let's go back to the home screen.",
                          descTextStyle: Theme.of(context).textTheme.bodyMedium,
                          tooltipBackgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          targetBorderRadius: BorderRadius.circular(30),
                          disposeOnTap:
                              false, // Keep the showcase active after tapping on target
                          onTargetClick: () {
                            if (currentPageIndex == 1) {
                              // If the current page is the map page, reverse the animation to go back to the home page
                              setState(() {
                                controller.reverse();
                                currentPageIndex =
                                    0; // Update the current page index to home page
                              });
                            }
                            ShowCaseWidget.of(context)
                                .next(); // Move to the next showcase step
                          },
                          tooltipActions: [
                            TooltipActionButton(
                                type: TooltipDefaultActionType.previous,
                                leadIcon: ActionButtonIcon(
                                  icon: Icon(
                                    Icons.arrow_back_ios,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ), // Icon
                                ),
                                name: "Previous",
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                onTap: () {
                                  if (currentPageIndex == 0) {
                                    // If the current page is the home page, make the animation go forward to the map page
                                    setState(() {
                                      controller.forward();
                                      currentPageIndex =
                                          1; // Update the current page index to map page
                                    });
                                  }
                                  ShowCaseWidget.of(context)
                                      .previous(); // Move to the previous showcase step
                                }),
                            TooltipActionButton(
                                type: TooltipDefaultActionType.next,
                                name: "Finish",
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                onTap: () {
                                  if (currentPageIndex == 1) {
                                    // If the current page is the map page, reverse the animation to go back to the home page
                                    setState(() {
                                      controller.reverse().then((_) {
                                        // Reverse the animation to go back to the home page
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          // Wait for the widget to be initialized
                                          ShowCaseWidget.of(context)
                                              .next(); // Move to the next showcase step
                                        });
                                      });
                                      currentPageIndex =
                                          0; // Update the current page index to home page
                                    });
                                  }
                                }),
                          ],
                          child: IconButton(
                            iconSize: 24,
                            onPressed: () {
                              if (currentPageIndex == 1) {
                                // If the current page is the map page, reverse the animation to go back to the home page
                                setState(() {
                                  controller.reverse();
                                  currentPageIndex =
                                      0; // Update the current page index to home page
                                });
                              }
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: currentPageIndex == 0
                                    ? Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer // Highlight the home button if on the home page
                                    : Colors
                                        .transparent, // Transparent background if not on the home page
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                currentPageIndex == 0
                                    ? Icons
                                        .home // Use filled icon if on the home page
                                    : Icons
                                        .home_outlined, // Use outlined icon if not on the home page
                                color: currentPageIndex == 0
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer // Use onSecondaryContainer color if on the home page
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface, // Use onSurface color if not on the home page
                              ),
                            ),
                          ),
                        ),
                        // Button to select or add a dog
                        Showcase(
                          key: menuNavBarButtonKey,
                          disableBarrierInteraction: true,
                          titleAlignment: Alignment.centerLeft,
                          title: "Manage dogs",
                          titleTextStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          descriptionAlignment: Alignment.centerLeft,
                          description:
                              "From this button, you can choose a dog or add one",
                          descTextStyle: Theme.of(context).textTheme.bodyMedium,
                          tooltipBackgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          targetBorderRadius: BorderRadius.circular(30),
                          child: PopupMenuButton<int>(
                            constraints: const BoxConstraints(
                              maxWidth: 60,
                            ),
                            clipBehavior: Clip.hardEdge,
                            position: PopupMenuPosition.over,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(60),
                            ),
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5),
                            icon: dogPicture.isNotEmpty
                                ? Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        width: 2,
                                        color: isOpen
                                            ? Colors.transparent
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary,
                                      ),
                                    ),
                                    child: !isOpen
                                        ? CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            foregroundImage: dogPicture[
                                                            selectedDog] ==
                                                        null ||
                                                    dogPicture[selectedDog]!
                                                        .isEmpty
                                                ? const AssetImage(
                                                    "assets/default_cane.jpeg") // Default image if no dog picture is available
                                                : Image.memory(dogPicture[
                                                        selectedDog]!)
                                                    .image, // Show the selected dog's picture if available
                                          )
                                        : const CircleAvatar(
                                            backgroundColor: Colors
                                                .transparent), // Show a transparent circle avatar when the menu is open, i.e. make the button disappear
                                  ) // Show the selected dog's picture
                                : Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        width: 2,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      backgroundColor: Colors.transparent,
                                      child: IconButton(
                                        iconSize: 24,
                                        onPressed: () {
                                          context.push("/Dog", extra: {
                                            "dog": Dog(
                                              dogID: "",
                                              name: "",
                                              breedID: -1,
                                              age: 0,
                                              sex: 0,
                                              size: "",
                                              weight: 0,
                                              coatType: "",
                                              allergies: [],
                                            ),
                                            "breeds": snapshot.data![3]
                                                as List<Breed>,
                                            "userID": widget.userID,
                                            "ip": widget.ip,
                                            "token": widget.token,
                                            "onEdit": () async {
                                              setState(() {
                                                user =
                                                    getUser(); // Refresh the user data
                                              });
                                              // Check if the next tutorial should be shown
                                              _checkNextTutorial();
                                            }
                                          }); // Navigate to the dog edit page to add a new dog
                                        },
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                      ),
                                    ),
                                  ), // Show an add icon if no dog is available
                            onCanceled: () {
                              setState(() {
                                isOpen = false; // Close the menu when canceled
                              });
                            },
                            onOpened: () {
                              setState(() {
                                isOpen = true; // Open the menu when opened
                              });
                            },
                            // This section is tricky. The values refer to the index in the builder. See that section to know why such strange indexes
                            onSelected: (int index) {
                              if (index == -999) {
                                return; // If the index is -999, do nothing (this is used for the add button)
                              }
                              if (index >= 0) {
                                // If the index is valid (not -1 or -999)
                                setState(() {
                                  selectedDog =
                                      index; // Update the selected dog index
                                  markersList = _getMarkersList(
                                      snapshot.data![2] as List<Store>,
                                      snapshot.data![0] as User,
                                      snapshot.data![1] as List<
                                          Reservation>); // Refresh the markers list based on the selected dog
                                  isOpen = false; // Close the menu
                                });
                                _scrollToSelectedDog(
                                    index); // Scroll to the selected dog
                              } else {
                                // If the index is -1, it means the user wants to add a new dog
                                context.push("/Dog", extra: {
                                  "dog": Dog(
                                    dogID: "",
                                    name: "",
                                    breedID: -1,
                                    age: 0,
                                    sex: 0,
                                    size: "Small",
                                    weight: 0,
                                    coatType: "Short",
                                    allergies: [],
                                  ),
                                  "userID": widget.userID,
                                  "breeds": snapshot.data![3] as List<Breed>,
                                  "ip": widget.ip,
                                  "token": widget.token,
                                  "onEdit": () async {
                                    setState(() {
                                      user = getUser(); // Refresh the user data
                                    });
                                  }
                                }); // Navigate to the dog edit page to add a new dog
                                setState(() {
                                  selectedDog =
                                      0; // Reset the selected dog index to 0
                                  isOpen = false; // Close the menu
                                });
                              }
                            },
                            // The items are built in an abnormal way. While each item should be a PopupMenuItem, in this case, the first item is a PopupMenuItem with a child that contains a ListView of all dogs, and the second item is the add button
                            // This is done to limit the number of visible dogs to 3 and make the menu scrollable if there are more than 3 dogs. Plus, the add button is always visible at the bottom, separated by a divider
                            itemBuilder: (BuildContext context) {
                              return [
                                PopupMenuItem(
                                    enabled: false,
                                    child: SizedBox(
                                      width: 60,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          dogPicture.isNotEmpty
                                              ? Container(
                                                  constraints: BoxConstraints(
                                                    maxHeight: dogPicture
                                                                .length >
                                                            3
                                                        ? 180
                                                        : dogPicture.length *
                                                            60.0, // Limit the height of the list to 3 dogs or less
                                                  ),
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.rectangle,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              60)),
                                                  child: ListView.builder(
                                                    clipBehavior: Clip.hardEdge,
                                                    padding: EdgeInsets.zero,
                                                    shrinkWrap: true,
                                                    itemCount:
                                                        dogPicture.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      int i = dogPicture
                                                              .length -
                                                          index -
                                                          1; // Reverse the index to show the most recent dog first
                                                      return InkWell(
                                                        onTap: () {
                                                          context.pop(
                                                              i); // Close the menu and return the selected dog index
                                                        },
                                                        child: Animate(
                                                          effects: [
                                                            SlideEffect(
                                                              begin:
                                                                  const Offset(
                                                                      0, 1),
                                                              end: const Offset(
                                                                  0, 0),
                                                              duration:
                                                                  duration,
                                                              curve: Curves
                                                                  .bounceInOut,
                                                              delay: Duration(
                                                                  milliseconds:
                                                                      index *
                                                                          100),
                                                            ), // Make the dog buttons slide in from the bottom with a bounce effect to build the menu in a cool way
                                                          ],
                                                          child: Container(
                                                            width: 60,
                                                            height: 60,
                                                            decoration:
                                                                BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              border:
                                                                  Border.all(
                                                                width: 2,
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary,
                                                              ),
                                                            ),
                                                            child: dogPicture[
                                                                            i] ==
                                                                        null ||
                                                                    dogPicture[
                                                                            i]!
                                                                        .isEmpty
                                                                ? const CircleAvatar(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .transparent,
                                                                    foregroundImage:
                                                                        AssetImage(
                                                                            "assets/default_cane.jpeg"),
                                                                  ) // Default image if no dog picture is available
                                                                : CircleAvatar(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .transparent,
                                                                    foregroundImage:
                                                                        Image.memory(dogPicture[i]!)
                                                                            .image,
                                                                  ), // Circle avatar with the dog's picture if available
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ) // Show a list of dogs if available
                                              : const SizedBox
                                                  .shrink(), // If no dogs are available, show an empty space
                                          if (dogPicture
                                              .isNotEmpty) // If there are dogs, show a divider
                                            Divider(
                                                height: 8,
                                                thickness: 1,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer),
                                        ],
                                      ),
                                    )),
                                // Button to add a new dog
                                PopupMenuItem<int>(
                                  value: -1,
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        width: 2,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    child: Icon(
                                      size: 24,
                                      Icons.add_circle_outline,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ];
                            },
                          ),
                        ),
                        // Map screen button
                        Showcase(
                          key: mapNavBarButtonKey,
                          disableBarrierInteraction: true,
                          titleAlignment: Alignment.centerLeft,
                          title: "Map button",
                          titleTextStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          descriptionAlignment: Alignment.centerLeft,
                          description:
                              "With this button, you can switch to the map",
                          descTextStyle: Theme.of(context).textTheme.bodyMedium,
                          tooltipBackgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          targetBorderRadius: BorderRadius.circular(30),
                          disposeOnTap: true,
                          onTargetClick: () {
                            if (currentPageIndex == 0) {
                              // If the current page is the home page, make the animation go forward to the map page
                              setState(() {
                                controller.forward().then((_) {
                                  // Wait for the animation to complete
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    // Wait for the widget to be initialized
                                    ShowCaseWidget.of(context)
                                        .next(); // Move to the next showcase step
                                  });
                                });
                                currentPageIndex =
                                    1; // Update the current page index to map page
                              });
                            }
                          },
                          tooltipActions: [
                            TooltipActionButton(
                              type: TooltipDefaultActionType.previous,
                              leadIcon: ActionButtonIcon(
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  size: 16,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ), // Icon
                              ), // ActionButtonIcon
                              name: "Previous",
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              onTap: ShowCaseWidget.of(context)
                                  .previous, // Move to the previous showcase step
                            ),
                            TooltipActionButton(
                                type: TooltipDefaultActionType.next,
                                name: "Next",
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                onTap: () {
                                  if (currentPageIndex == 0) {
                                    // If the current page is the home page, make the animation go forward to the map page
                                    setState(() {
                                      controller.forward().then((_) {
                                        // Wait for the animation to complete
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          // Wait for the widget to be initialized
                                          ShowCaseWidget.of(context)
                                              .next(); // Move to the next showcase step
                                        });
                                      });
                                      currentPageIndex =
                                          1; // Update the current page index to map page
                                    });
                                  } else {
                                    ShowCaseWidget.of(context)
                                        .next(); // Move to the next showcase step
                                  }
                                }),
                          ],
                          child: IconButton(
                            iconSize: 24,
                            onPressed: () {
                              if (currentPageIndex == 0) {
                                // If the current page is the home page, make the animation go forward to the map page
                                setState(() {
                                  controller
                                      .forward(); // Start the animation to go to the map page
                                  currentPageIndex =
                                      1; // Update the current page index to map page
                                });
                              }
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: currentPageIndex == 1
                                    ? Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer // Highlight the map button if on the map page
                                    : Colors
                                        .transparent, // Transparent background if not on the map page
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                currentPageIndex == 1
                                    ? Icons
                                        .map // Use the filled icon if on the map page
                                    : Icons
                                        .map_outlined, // Use the outlined icon if not on the map page
                                color: currentPageIndex == 1
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer // Use onSecondaryContainer color if on the map page
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface, // Use onSurface color if not on the map page
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Body of the home page with a refresh indicator, i.e. a pull-down-to-refresh feature
            body: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  user = getUser(); // Refresh the user data
                  prenotazioni = getReservations(); // Refresh the reservations
                  stores = getStores(); // Refresh the stores
                  markersList = _getMarkersList(
                      snapshot.data![2] as List<Store>,
                      snapshot.data![0] as User,
                      snapshot.data![1] as List<Reservation>);
                }); // Refresh the markers list based on the updated data
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Refresh completed"),
                    duration: const Duration(seconds: 1),
                  ),
                ); // Show a snackbar to indicate that the refresh is complete
              },
              // The body contains a Stack with two SlideTransitions for the home and map pages. In this way, we can switch between the two pages with a sliding animation. One page goes out from the screen while the other comes in. Default is the home page
              child: Stack(
                children: [
                  // Home page
                  SlideTransition(
                    position: controller.drive(
                      Tween<Offset>(
                        begin: Offset.zero,
                        end: const Offset(-1, 0), // Slide out to the left
                      ),
                    ),
                    child: Showcase(
                      key: homePageKey,
                      titleAlignment: Alignment.centerLeft,
                      title: "Welcome to IoTail Companion app",
                      titleTextStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      descriptionAlignment: Alignment.centerLeft,
                      description:
                          "This is your home screen. You can see your dogs and reservations here.",
                      descTextStyle: Theme.of(context).textTheme.bodyMedium,
                      tooltipBackgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Home(
                        selectedDog: selectedDog,
                        onDogSelected: (int index) {
                          setState(() {
                            selectedDog =
                                index; // Update the selected dog index
                          });
                          _scrollToSelectedDog(
                              index); // Scroll to the selected dog
                        },
                        scrollController: _scrollController,
                        onDogUpdated: () {
                          setState(() {
                            user = getUser(); // Refresh the user data
                            dogPicture = (snapshot.data![0] as User)
                                .dogs
                                .map((dog) => dog.picture)
                                .toList(); // Refresh the dog pictures
                          });
                          _checkNextTutorial(); // Check whether to show the dog tutorial
                        },
                        onReservationsUpdated: () {
                          setState(() {
                            prenotazioni =
                                getReservations(); // Refresh the reservations
                            stores = getStores(); // Refresh the stores
                            markersList = _getMarkersList(
                                snapshot.data![2] as List<Store>,
                                snapshot.data![0] as User,
                                snapshot.data![1] as List<Reservation>);
                          }); // Refresh the markers list based on the updated data
                          _checkNextTutorial(); // Check whether to show the reservation tutorial
                        },
                        user: snapshot.data![0] as User, // User data
                        breeds: snapshot.data![3] as List<Breed>, // Dog breeds
                        reservations: snapshot.data![1]
                            as List<Reservation>, // Reservations
                        shops: snapshot.data![2] as List<Store>, // Stores data
                        client: snapshot.data![4]
                            as MqttServerClient, // MQTT client
                      ),
                    ),
                  ),
                  // Map page
                  SlideTransition(
                    position: controller.drive(
                      Tween<Offset>(
                        begin: const Offset(1, 0), // Slide in from the right
                        end: Offset.zero,
                      ),
                    ),
                    child: Showcase(
                      key: mapPageKey,
                      titleAlignment: Alignment.centerLeft,
                      title: "Map screen",
                      titleTextStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      descriptionAlignment: Alignment.centerLeft,
                      description:
                          "This is the map screen. Here, you can see all the stores that have available kennels. Tap on a paw to reserve a kennel through the dedicated button.",
                      descTextStyle: Theme.of(context).textTheme.bodyMedium,
                      tooltipBackgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      tooltipActions: [
                        TooltipActionButton(
                            type: TooltipDefaultActionType.previous,
                            leadIcon: ActionButtonIcon(
                              icon: Icon(
                                Icons.arrow_back_ios,
                                size: 16,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ), // Icon
                            ), // ActionButtonIcon
                            name: "Previous",
                            textStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            onTap: () {
                              if (currentPageIndex == 1) {
                                // If the current page is the map page, reverse the animation to the home page
                                setState(() {
                                  controller
                                      .reverse(); // Start the animation to go back to the home page
                                  currentPageIndex =
                                      0; // Update the current page index to home page
                                });
                              }
                              ShowCaseWidget.of(context)
                                  .previous(); // Move to the previous showcase step
                            }),
                        TooltipActionButton(
                            type: TooltipDefaultActionType.next,
                            name: "Next",
                            textStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer),
                            hideActionWidgetForShowcase: [
                              mapNavBarButtonKey
                            ], // hide on last showcase
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            onTap: ShowCaseWidget.of(context)
                                .next), // Move to the next showcase step
                      ],
                      child: OSMMap(
                        markerslist: markersList,
                        onPrepareReservation: (marker) => selectedShop = marker,
                        onSubmitReservation: () async {
                          Map<String, dynamic> data = {
                            "dogID": (snapshot.data![0] as User)
                                .dogs[selectedDog]
                                .dogID,
                            "userID": widget.userID,
                            "storeID": selectedShop.id,
                            "dog_size": (snapshot.data![0] as User)
                                .dogs[selectedDog]
                                .size,
                          }; // Prepare the data for the reservation
                          final response = await reserveKennel(
                              data); // Call the API to reserve the kennel
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response),
                              duration: const Duration(seconds: 3),
                            ),
                          ); // Show a snackbar with the response from the API
                          setState(() {
                            prenotazioni =
                                getReservations(); // Refresh the reservations
                            stores = getStores(); // Refresh the stores
                            markersList = _getMarkersList(
                                snapshot.data![2] as List<Store>,
                                snapshot.data![0] as User,
                                snapshot.data![1] as List<Reservation>);
                          }); // Refresh the markers list based on the updated data
                          _checkNextTutorial(); // Check whether to show the reservation tutorial
                        },
                        onRefreshKennels: () {
                          setState(() {
                            stores = getStores(); // Refresh the stores
                            markersList = _getMarkersList(
                                snapshot.data![2] as List<Store>,
                                snapshot.data![0] as User,
                                snapshot.data![1] as List<Reservation>);
                          }); // Refresh the markers list based on the updated data
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Kennels refreshed"),
                              duration: const Duration(seconds: 1),
                            ),
                          ); // Show a snackbar to indicate that the kennels have been refreshed
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Floating action button to unlock a kennel without booking it first
            floatingActionButton: Showcase(
              key: unlockKennelFABKey,
              titleAlignment: Alignment.centerLeft,
              title: "Unlock Kennel Button",
              titleTextStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              descriptionAlignment: Alignment.centerLeft,
              description:
                  "From this button, you can unlock a kennel without booking it first. You must use it only when you are right in front of the kennel.",
              descTextStyle: Theme.of(context).textTheme.bodyMedium,
              tooltipBackgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              targetBorderRadius: BorderRadius.circular(20),
              targetPadding: EdgeInsets.all(8),
              child: FloatingActionButton.extended(
                  onPressed: () {
                    _showUnlockKennelDialog(
                        context,
                        snapshot.data![0] as User,
                        snapshot.data![2] as List<Store>,
                        snapshot.data![1] as List<
                            Reservation>); // Show the dialog to unlock a kennel
                  },
                  label: Text("Unlock Kennel")),
            ),
          );
        } else if (snapshot.hasError) {
          // If there is an error in the snapshot (i.e. data fetching failed)
          String msg = snapshot.error.toString(); // Get the error message
          return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              forceMaterialTransparency: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.inversePrimary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(
                    bounds), // // Gradient for the title text from top left to bottom right
                child: const Text(
                  'IoTail',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Give the user the option to refresh the data by pulling down the screen or pressing the refresh button
            body: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  user = getUser(); // Refresh the user data
                  prenotazioni = getReservations(); // Refresh the reservations
                  stores = getStores(); // Refresh the stores
                  markersList = _getMarkersList(
                      snapshot.data![2] as List<Store>,
                      snapshot.data![0] as User,
                      snapshot.data![1] as List<
                          Reservation>); // Refresh the markers list based on the updated data
                });
              },
              child: Center(
                child: Column(
                  children: [
                    Text(msg),
                  ],
                ),
              ),
            ),
            // Floating action button to refresh the data
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                setState(() {
                  user = getUser(); // Refresh the user data
                  prenotazioni = getReservations(); // Refresh the reservations
                  stores = getStores(); // Refresh the stores
                  markersList = _getMarkersList(
                      snapshot.data![2] as List<Store>,
                      snapshot.data![0] as User,
                      snapshot.data![1] as List<Reservation>);
                }); // Refresh the markers list based on the updated data
              },
              child: Icon(Icons.refresh),
            ),
          );
        }
        // If the snapshot is still loading, show a loading indicator
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            forceMaterialTransparency: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.inversePrimary,
                  Theme.of(context).colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(
                  bounds), // Gradient for the title text from top left to bottom right
              child: const Text(
                'IoTail',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          body: const Center(
            child:
                CircularProgressIndicator(), // Show a loading indicator while the data is being fetched
          ),
        );
      },
    );
  }
}
