import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:holdable_button/holdable_button.dart';
import 'package:holdable_button/utils/utils.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:slide_countdown/slide_countdown.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:iotail_companion/util/user.dart';
import 'package:iotail_companion/util/breed.dart';
import 'package:iotail_companion/util/requests.dart' as requests;
import 'package:iotail_companion/util/reservation.dart';
import 'package:iotail_companion/util/store.dart';
import 'package:iotail_companion/util/tutorial_keys.dart';

// Home widget to display the user's dogs and reservations
class Home extends StatefulWidget {
  final Function(int) onDogSelected; // Callback to handle dog selection
  final int selectedDog; // Index of the currently selected dog
  final User user; // User data containing the list of dogs
  final List<Reservation> reservations; // List of reservations for the user
  final List<Breed> breeds; // List of breeds available
  final List<Store> shops; // List of shops available
  final ScrollController scrollController; // Scroll controller for the dog list
  final VoidCallback onDogUpdated; // Callback to handle dog updates
  final VoidCallback
      onReservationsUpdated; // Callback to handle reservation updates
  final MqttServerClient client; // MQTT client for communication

  const Home(
      {super.key,
      required this.selectedDog,
      required this.onDogSelected,
      required this.onReservationsUpdated,
      required this.user,
      required this.breeds,
      required this.reservations,
      required this.shops,
      required this.scrollController,
      required this.onDogUpdated,
      required this.client});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  late String? ip;
  late String name;
  late String phone;
  late FlutterSecureStorage
      storage; // Declaring secure storage variable for persistently storing data or writing precedently stored data. This allows to persist information after the app is closed.
  final TextEditingController _unlockCodeController = TextEditingController();

  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      ); // Using encrypted shared preferences for secure storage on Android

  bool editMode = false; // Flag to indicate if the dogs are in edit mode
  late AnimationController
      _animationController; // Animation controller for the dog cards
  late Animation<double> _animation; // Animation for the dog cards

  /// Retrieves the IP address from the storage.
  Future<void> setup() async {
    ip = await storage.read(key: "ip");
  }

  /// Shows a confirmation dialog for canceling a reservation.
  Future<bool> _showReservationCancelConfirmation(
      BuildContext context, Reservation reservation) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Confirm reservation cancellation",
          textAlign: TextAlign.center,
        ),
        content: const Text("Are you sure you want to cancel the reservation?"),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              context.pop(false);
            },
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              final String? token = await storage.read(
                  key: "token"); // Retrieve the token from the storage
              Map response = await requests.cancel_reservation(
                  ip!,
                  token!,
                  reservation
                      .reservationID); // Call the cancel reservation API with the IP, token, and reservation ID
              if (response["message"].contains("Failed")) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(response["message"]),
                    duration: const Duration(seconds: 3),
                  ),
                ); // Show a snackbar with the error message if the cancellation failed
                context.pop(
                    false); // Close the dialog without confirming the cancellation
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Reservation cancel successful"),
                    duration: const Duration(seconds: 3),
                  ),
                ); // Show a snackbar with a success message if the cancellation was successful
                widget
                    .onReservationsUpdated(); // Call the callback to update the reservations list
                context
                    .pop(true); // Close the dialog and confirm the cancellation
              }
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog to confirm the activation of a reservation.
  Future<void> _showReservationActivationDialog(
      BuildContext context, Reservation reservation) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Confirm reservation activation",
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                "Enter kennel unlock code for kennel ${reservation.kennelID.toString().padLeft(3, '0')}"),
            TextField(
              controller: _unlockCodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Unlock code",
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          // Cancel button to clear the input and close the dialog
          TextButton(
            onPressed: () {
              _unlockCodeController.clear();
              context.pop();
            },
            child: const Text("Cancel"),
          ),
          // Confirm button to activate the reservation
          TextButton(
            onPressed: () async {
              final String? token = await storage.read(
                  key: "token"); // Retrieve the token from the storage
              Map response = await requests.activate_reservation(
                  ip!,
                  token!,
                  reservation.reservationID,
                  int.tryParse(_unlockCodeController.text) ??
                      -1); // Call the activate reservation API with the IP, token, reservation ID, and unlock code
              _unlockCodeController
                  .clear(); // Clear the input field after the request
              if (response["message"].contains("Failed")) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(response["message"]),
                    duration: const Duration(seconds: 3),
                  ),
                ); // Show a snackbar with the error message if the activation failed
                context
                    .pop(); // Close the dialog without confirming the activation
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Reservation activation successful"),
                    duration: const Duration(seconds: 3),
                  ),
                ); // Show a snackbar with a success message if the activation was successful
                widget
                    .onReservationsUpdated(); // Call the callback to update the reservations list
                context.pop(); // Close the dialog and confirm the activation
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    storage = FlutterSecureStorage(
        aOptions:
            _getAndroidOptions()); // Initialize secure storage with Android options
    setup(); // Call the setup method to retrieve the IP address
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    )..repeat(reverse: true); // Loops back and forth
    _animation = Tween<double>(
      begin: -0.01, // Small rotation to left
      end: 0.01, // Small rotation to right
    ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves
            .easeInOut)); // Create an animation that rotates the dog cards slightly back and forth
    super.initState();
  }

  @override
  void dispose() {
    _animationController
        .dispose(); // Dispose of the animation controller to free up resources
    super.dispose();
  }

  /// Toggles the edit mode for the dog cards.
  void _toggleEditMode() {
    setState(() {
      editMode = !editMode; // Toggle the edit mode flag
      if (editMode) {
        _animationController.repeat(
            reverse: true); // Start the animation when entering edit mode
      } else {
        _animationController
            .stop(); // Stop the animation when exiting edit mode
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.user.dogs.isEmpty ? "Add a dog." : "Dogs:",
            style: TextStyle(fontSize: 40),
          ),
          // Horizontal list of dog cards to display the user's dogs
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.2),
            child: ListView.separated(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.user.dogs.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                    radius: 5,
                    onTap: () {
                      widget.onDogSelected(index);
                    },
                    onLongPress: _toggleEditMode,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset:
                              Offset(0, editMode ? _animation.value * 100 : 0),
                          child: Transform.rotate(
                            angle: editMode ? _animation.value : 0,
                            child: child,
                          ),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Showcase(
                            key: index == 0
                                ? dogCardKey
                                : GlobalKey(), // Only the first dog card has the tutorial
                            disableBarrierInteraction:
                                true, // Disable interaction with the rest of the screen while the tooltip is shown
                            title: "Your dog card",
                            titleAlignment: Alignment.centerLeft,
                            titleTextStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            descriptionAlignment: Alignment.centerLeft,
                            description:
                                "This is your dog's information card. Tap to select it, or long press to enter edit mode.",
                            descTextStyle:
                                Theme.of(context).textTheme.bodyMedium,
                            tooltipBackgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            tooltipActions: [
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
                                    ShowCaseWidget.of(context)
                                        .next(); // Move to the next tooltip
                                  }),
                            ],
                            targetBorderRadius: BorderRadius.circular(15),
                            child: Card(
                              elevation: widget.selectedDog == index
                                  ? 5
                                  : 1, // Increase elevation for the selected dog card
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: widget.selectedDog == index
                                          ? 3
                                          : 1), // Highlight the selected dog card with a thicker border
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 300,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline
                                                  .withOpacity(0.5),
                                              width: 1,
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                11), // Slightly smaller radius to match the border
                                            child: widget.user.dogs[index]
                                                            .picture ==
                                                        null ||
                                                    widget.user.dogs[index]
                                                        .picture!.isEmpty
                                                ? Image.asset(
                                                    "assets/default_cane.jpeg",
                                                    fit: BoxFit.cover,
                                                    width: 120,
                                                    height: 120,
                                                  ) // Default image if no picture is available
                                                : Image.memory(
                                                    widget.user.dogs[index]
                                                        .picture!,
                                                    fit: BoxFit.cover,
                                                    width: 120,
                                                    height: 120,
                                                  ), // Display the dog's picture if available
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 8,
                                        ), // Spacing between the image and text
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  widget.user.dogs
                                                      .elementAt(index)
                                                      .name, // Display the dog's name
                                                  style: const TextStyle(
                                                      fontSize: 40,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text(
                                                widget.breeds
                                                    .firstWhere((breed) =>
                                                        breed.breedID ==
                                                        widget.user.dogs
                                                            .elementAt(index)
                                                            .breedID)
                                                    .name, // Display the dog's breed name
                                                style: const TextStyle(
                                                    fontSize: 20),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (editMode) // Show edit button only in edit mode
                            IconButton(
                                style: ButtonStyle(
                                    shape: WidgetStateProperty.all(
                                        CircleBorder())),
                                onPressed: () async {
                                  String? token = await storage.read(
                                      key:
                                          "token"); // Retrieve the token from the storage
                                  context.push(
                                    "/Dog",
                                    extra: {
                                      "dog": widget.user.dogs.elementAt(index),
                                      "breeds": widget.breeds,
                                      "userID": widget.user.userID,
                                      "ip": ip,
                                      "token": token,
                                      "onEdit": () {
                                        widget.onDogUpdated();
                                      }
                                    },
                                  ); // Navigate to the dog edit screen with the necessary data
                                  editMode =
                                      false; // Exit edit mode after editing a dog
                                },
                                icon: const Icon(Icons.edit)),
                        ],
                      ),
                    ));
              },
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(width: 8); // Spacing between dog cards
              },
            ),
          ),
          if (widget.reservations
              .isNotEmpty) // Divider to separate the dog list from the reservations section, only if there are reservations
            Divider(
              color: Theme.of(context).colorScheme.primary,
              thickness: 2,
            ),
          if (widget.reservations
              .isNotEmpty) // Display the reservations section only if there are reservations
            const Text(
              "Reservations:",
              style: TextStyle(fontSize: 40),
            ),
          // List of reservations for the user
          Expanded(
            child: ListView.separated(
                itemBuilder: (BuildContext context, int index) {
                  DateTime startTime = DateTime.fromMillisecondsSinceEpoch(widget
                          .reservations
                          .elementAt(index)
                          .reservationTime *
                      1000); // Convert reservation time from seconds to milliseconds
                  DateTime endtime = startTime.add(Duration(
                      minutes:
                          30)); // Assuming each reservation lasts 30 minutes
                  Duration remainingTime = endtime.difference(DateTime
                      .now()); // Calculate the remaining time until the reservation ends
                  return Dismissible(
                    background: Container(
                      padding: EdgeInsets.all(8),
                      alignment: Alignment.centerRight,
                      color: Colors.red,
                      child: const Icon(
                        size: 40,
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    direction: !widget.reservations.elementAt(index).active
                        ? DismissDirection.endToStart
                        : DismissDirection
                            .none, // Allow swiping to delete only for non-active reservations
                    onDismissed: (direction) {
                      _showReservationCancelConfirmation(
                          context,
                          widget.reservations.elementAt(
                              index)); // Show confirmation dialog when swiping to delete
                    },
                    key: Key(widget.reservations
                        .elementAt(index)
                        .reservationID
                        .toString()),
                    confirmDismiss: (direction) {
                      return _showReservationCancelConfirmation(
                          context,
                          widget.reservations.elementAt(
                              index)); // Confirm dismissal by showing the cancellation dialog
                    },
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Showcase(
                          key: index == 0
                              ? reservationCardKey
                              : GlobalKey(), // Only the first reservation card has the tutorial
                          disableBarrierInteraction:
                              true, // Disable interaction with the rest of the screen while the tooltip is shown
                          title: "Dog reservation",
                          titleAlignment: Alignment.centerLeft,
                          titleTextStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          descriptionAlignment: Alignment.centerLeft,
                          description: !widget.reservations
                                  .elementAt(index)
                                  .active // Check if the reservation is active and display the appropriate description
                              ? "This is your reservation. You can activate it with the dedicated button or cancel it with the button or by swiping from right to left. When a reservation is active, you can check details by pressing the top right button."
                              : "This is your active reservation. You can check details by pressing the top right button.",
                          descTextStyle: Theme.of(context).textTheme.bodyMedium,
                          tooltipBackgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          tooltipActions: [
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
                                  ShowCaseWidget.of(context)
                                      .next(); // Move to the next tooltip
                                }),
                          ],
                          targetBorderRadius: BorderRadius.circular(18),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: widget.reservations
                                        .elementAt(index)
                                        .active
                                    ? 3
                                    : 1, // Highlight the active reservation with a thicker border
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: SizedBox(
                                width: double.infinity,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Text displaying the dog's name
                                    Text(
                                        "Dog: ${widget.user.dogs.firstWhere((dog) => dog.dogID == widget.reservations.elementAt(index).dogID).name}",
                                        style: const TextStyle(fontSize: 40)),
                                    // Text displaying the reservation shop and kennel information
                                    Text(
                                        "${widget.shops.firstWhere((shop) => shop.id == widget.reservations.elementAt(index).storeID).name}, kennel: ${widget.reservations.elementAt(index).kennelID.toString().padLeft(3, '0')}",
                                        style: const TextStyle(fontSize: 20)),
                                    if (!widget.reservations
                                        .elementAt(index)
                                        .active) // Show countdown only if the reservation is not active
                                      SlideCountdown(
                                        duration: remainingTime,
                                        slideDirection: SlideDirection.up,
                                        separator: ":",
                                        separatorStyle: TextStyle(fontSize: 20),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface,
                                        ),
                                        style: const TextStyle(fontSize: 20),
                                        onDone: () async {
                                          Future.delayed(
                                              const Duration(seconds: 5), () {
                                            widget
                                                .onReservationsUpdated(); // Refresh reservations after countdown ends (5 seconds delay to account for app-server time mismatch)
                                          });
                                        },
                                      ),
                                    widget.reservations
                                            .elementAt(index)
                                            .active // if the reservation is active, show the holdable button to cancel the reservation, otherwise show the activation or cancellation buttons
                                        ? Container(
                                            margin:
                                                const EdgeInsets.only(top: 8),
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.red,
                                                    width: 2),
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            child: HoldableButton(
                                              loadingType:
                                                  LoadingType.fillingLoading,
                                              buttonColor: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                              loadingColor: Colors.red,
                                              duration: 5,
                                              radius: 10,
                                              beginFillingPoint:
                                                  Alignment.centerLeft,
                                              endFillingPoint:
                                                  Alignment.centerRight,
                                              resetAfterFinish: true,
                                              onConfirm: () async {
                                                final String? token =
                                                    await storage.read(
                                                        key:
                                                            "token"); // Retrieve the token from the storage
                                                Map response = await requests
                                                    .cancel_reservation(
                                                        ip!,
                                                        token!,
                                                        widget.reservations
                                                            .elementAt(index)
                                                            .reservationID); // Call the cancel reservation API with the IP, token, and reservation ID
                                                if (response["message"]
                                                    .contains("Failed")) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          response["message"]),
                                                      duration: const Duration(
                                                          seconds: 3),
                                                    ),
                                                  ); // Show a snackbar with the error message if the cancellation failed
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: const Text(
                                                          "Reservation cancel successful"),
                                                      duration: const Duration(
                                                          seconds: 3),
                                                    ),
                                                  ); // Show a snackbar with a success message if the cancellation was successful
                                                  widget
                                                      .onReservationsUpdated(); // Call the callback to update the reservations list
                                                }
                                              },
                                              strokeWidth: 1,
                                              hasVibrate: true,
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              height: 50,
                                              child: const Text(
                                                "HOLD TO CONFIRM TERMINATION",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              // Button to activate the reservation
                                              TextButton(
                                                  style: ButtonStyle(
                                                      backgroundColor: WidgetStateProperty.all(
                                                          Colors.green),
                                                      shape: WidgetStateProperty.all(
                                                          RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(
                                                                  5)))),
                                                  onPressed: () => _showReservationActivationDialog(
                                                      context,
                                                      widget.reservations.elementAt(
                                                          index)), // Show dialog to activate the reservation
                                                  child: const Text("Activate",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold))),
                                              // Button to cancel the reservation
                                              IconButton(
                                                  style: ButtonStyle(
                                                      backgroundColor:
                                                          WidgetStateProperty.all(
                                                              Colors.red),
                                                      shape: WidgetStateProperty.all(
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5)))),
                                                  color: Colors.white,
                                                  onPressed: () =>
                                                      _showReservationCancelConfirmation(
                                                          context,
                                                          widget.reservations
                                                              .elementAt(
                                                                  index)), // Show confirmation dialog to cancel the reservation
                                                  icon: const Icon(Icons.delete)),
                                            ],
                                          )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (widget.reservations
                            .elementAt(index)
                            .active) // Show the button to open the reservation details only if the reservation is active
                          IconButton(
                            onPressed: () {
                              int kennelID = widget.reservations
                                  .elementAt(index)
                                  .kennelID; // Get the kennel ID from the reservation
                              context.push("/ReservationScreen", extra: {
                                "reservation":
                                    widget.reservations.elementAt(index),
                                "dog": widget.user.dogs.firstWhere((dog) =>
                                    dog.dogID ==
                                    widget.reservations.elementAt(index).dogID),
                                "ip": ip,
                                "client": widget.client, // Pass the client
                                "onReservationCancel": () async {
                                  final String? token = await storage.read(
                                      key:
                                          "token"); // Retrieve the token from the storage
                                  Map response = await requests.cancel_reservation(
                                      ip!,
                                      token!,
                                      widget.reservations
                                          .elementAt(index)
                                          .reservationID); // Call the cancel reservation API with the IP, token, and reservation ID
                                  if (response["message"].contains("Failed")) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(response["message"]),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    ); // Show a snackbar with the error message if the cancellation failed
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            "Reservation cancel successful"),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    ); // Show a snackbar with a success message if the cancellation was successful
                                    widget
                                        .onReservationsUpdated(); // Call the callback to update the reservations list
                                  }
                                }
                              }); // Navigate to the reservation details screen with the reservation data, dog data, IP, client, and cancellation callback
                              final builder =
                                  MqttPayloadBuilder(); // Create a new MQTT payload builder
                              builder.addString(jsonEncode({
                                "message": "off"
                              })); // Add a string payload to the builder to turn off the camera
                              widget.client.publishMessage(
                                  "IoTail/kennel$kennelID/camera",
                                  MqttQos.exactlyOnce,
                                  builder
                                      .payload!); // Publish the MQTT message to turn off the camera for the specified kennel
                            },
                            icon: Icon(Icons.open_in_new),
                            color: Theme.of(context).colorScheme.primary,
                          )
                      ],
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(
                    height: 8,
                  ); // Spacing between reservation cards
                },
                itemCount: widget.reservations.length),
          ),
        ],
      ),
    );
  }
}
