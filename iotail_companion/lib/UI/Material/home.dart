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

class Home extends StatefulWidget {
  final Function(int) onDogSelected;
  final int selectedDog;
  final User user;
  final List<Reservation> reservations;
  final List<Breed> breeds;
  final List<Store> shops;
  final ScrollController scrollController;
  final VoidCallback onDogUpdated;
  final VoidCallback onReservationsUpdated;
  final MqttServerClient client;

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
  late FlutterSecureStorage storage;
  final TextEditingController _unlockCodeController = TextEditingController();

  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  bool editMode = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  Future<void> setup() async {
    ip = await storage.read(key: "ip");
  }

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
              final String? token = await storage.read(key: "token");
              Map response = await requests.cancel_reservation(
                  ip!, token!, reservation.reservationID);
              if (response["message"].contains("Failed")) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(response["message"]),
                    duration: const Duration(seconds: 3),
                  ),
                );
                context.pop(false);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Reservation cancel successful"),
                    duration: const Duration(seconds: 3),
                  ),
                );
                widget.onReservationsUpdated();
                context.pop(true);
              }
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

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
          TextButton(
            onPressed: () {
              _unlockCodeController.clear();
              context.pop();
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final String? token = await storage.read(key: "token");
              Map response = await requests.activate_reservation(
                  ip!,
                  token!,
                  reservation.reservationID,
                  int.tryParse(_unlockCodeController.text) ?? -1);
              _unlockCodeController.clear();
              if (response["message"].contains("Failed")) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(response["message"]),
                    duration: const Duration(seconds: 3),
                  ),
                );
                context.pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Reservation activation successful"),
                    duration: const Duration(seconds: 3),
                  ),
                );
                widget.onReservationsUpdated();
                context.pop();
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
    storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    setup();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    )..repeat(reverse: true); // Loops back and forth
    _animation = Tween<double>(
      begin: -0.01, // Small rotation to left
      end: 0.01, // Small rotation to right
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    super.initState();
  }

  @override
  void didUpdateWidget(Home oldwidget) {
    super.didUpdateWidget(oldwidget);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      editMode = !editMode;
      if (editMode) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
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
                                : GlobalKey(), // Solo la prima card ha il tutorial
                            disableBarrierInteraction: true,
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
                                    ShowCaseWidget.of(context).next();
                                  }),
                            ],
                            targetBorderRadius: BorderRadius.circular(15),
                            child: Card(
                              elevation: widget.selectedDog == index ? 5 : 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width:
                                          widget.selectedDog == index ? 3 : 1),
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
                                                11), // Leggermente più piccolo del container
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
                                                  )
                                                : Image.memory(
                                                    widget.user.dogs[index]
                                                        .picture!,
                                                    fit: BoxFit.cover,
                                                    width: 120,
                                                    height: 120,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 8,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  widget.user.dogs
                                                      .elementAt(index)
                                                      .name,
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
                                                    .name,
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
                          if (editMode)
                            IconButton(
                                style: ButtonStyle(
                                    shape: WidgetStateProperty.all(
                                        CircleBorder())),
                                onPressed: () async {
                                  String? token =
                                      await storage.read(key: "token");
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
                                  );
                                  editMode = false;
                                },
                                icon: const Icon(Icons.edit)),
                        ],
                      ),
                    ));
              },
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(width: 8);
              },
            ),
          ),
          if (widget.reservations.isNotEmpty)
            Divider(
              color: Theme.of(context).colorScheme.primary,
              thickness: 2,
            ),
          if (widget.reservations.isNotEmpty)
            const Text(
              "Reservations:",
              style: TextStyle(fontSize: 40),
            ),
          Expanded(
            child: ListView.separated(
                itemBuilder: (BuildContext context, int index) {
                  DateTime startTime = DateTime.fromMillisecondsSinceEpoch(
                      widget.reservations.elementAt(index).reservationTime *
                          1000);
                  DateTime endtime = startTime.add(Duration(minutes: 30));
                  Duration remainingTime = endtime.difference(DateTime.now());
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
                        : DismissDirection.none,
                    onDismissed: (direction) {
                      _showReservationCancelConfirmation(
                          context, widget.reservations.elementAt(index));
                    },
                    key: Key(widget.reservations
                        .elementAt(index)
                        .reservationID
                        .toString()),
                    confirmDismiss: (direction) {
                      return _showReservationCancelConfirmation(
                          context, widget.reservations.elementAt(index));
                    },
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Showcase(
                          key: index == 0
                              ? reservationCardKey
                              : GlobalKey(), // Solo la prima reservation ha il tutorial
                          disableBarrierInteraction: true,
                          title: "Dog reservation",
                          titleAlignment: Alignment.centerLeft,
                          titleTextStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          descriptionAlignment: Alignment.centerLeft,
                          description: !widget.reservations
                                  .elementAt(index)
                                  .active
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
                                  ShowCaseWidget.of(context).next();
                                }),
                          ],
                          targetBorderRadius: BorderRadius.circular(18),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width:
                                    widget.reservations.elementAt(index).active
                                        ? 3
                                        : 1,
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
                                    Text(
                                        "Dog: ${widget.user.dogs.firstWhere((dog) => dog.dogID == widget.reservations.elementAt(index).dogID).name}",
                                        style: const TextStyle(fontSize: 40)),
                                    Text(
                                        "${widget.shops.firstWhere((shop) => shop.id == widget.reservations.elementAt(index).storeID).name}, kennel: ${widget.reservations.elementAt(index).kennelID.toString().padLeft(3, '0')}",
                                        style: const TextStyle(fontSize: 20)),
                                    if (!widget.reservations
                                        .elementAt(index)
                                        .active)
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
                                            widget.onReservationsUpdated();
                                          });
                                        },
                                      ),
                                    widget.reservations.elementAt(index).active
                                        ? Container(
                                            margin:
                                                const EdgeInsets.only(top: 8),
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.red,
                                                    width: 2),
                                                borderRadius:
                                                    BorderRadius.circular(10)),
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
                                                        key: "token");
                                                Map response = await requests
                                                    .cancel_reservation(
                                                        ip!,
                                                        token!,
                                                        widget.reservations
                                                            .elementAt(index)
                                                            .reservationID);
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
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: const Text(
                                                          "Reservation cancel successful"),
                                                      duration: const Duration(
                                                          seconds: 3),
                                                    ),
                                                  );
                                                  widget
                                                      .onReservationsUpdated();
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
                                              if (!widget.reservations
                                                  .elementAt(index)
                                                  .active)
                                                TextButton(
                                                    style: ButtonStyle(
                                                        backgroundColor:
                                                            WidgetStateProperty.all(
                                                                Colors.green),
                                                        shape: WidgetStateProperty.all(
                                                            RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                        5)))),
                                                    onPressed: () =>
                                                        _showReservationActivationDialog(
                                                            context,
                                                            widget.reservations
                                                                .elementAt(index)),
                                                    child: const Text("Activate", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                              IconButton(
                                                  style: ButtonStyle(
                                                      backgroundColor:
                                                          WidgetStateProperty
                                                              .all(Colors.red),
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
                                                              .elementAt(index)),
                                                  icon: const Icon(Icons.delete)),
                                            ],
                                          )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (widget.reservations.elementAt(index).active)
                          IconButton(
                            onPressed: () async {
                              int kennelID =
                                  widget.reservations.elementAt(index).kennelID;
                              await context.push("/ReservationScreen", extra: {
                                "reservation":
                                    widget.reservations.elementAt(index),
                                "dog": widget.user.dogs.firstWhere((dog) =>
                                    dog.dogID ==
                                    widget.reservations.elementAt(index).dogID),
                                "ip": ip,
                                "client": widget.client, // Pass the client
                                "onReservationCancel": () async {
                                  final String? token =
                                      await storage.read(key: "token");
                                  Map response =
                                      await requests.cancel_reservation(
                                          ip!,
                                          token!,
                                          widget.reservations
                                              .elementAt(index)
                                              .reservationID);
                                  if (response["message"].contains("Failed")) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(response["message"]),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            "Reservation cancel successful"),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                    widget.onReservationsUpdated();
                                  }
                                }
                              });
                              final builder = MqttPayloadBuilder();
                              builder.addString(jsonEncode({"message": "off"}));
                              widget.client.publishMessage(
                                  "IoTail/kennel$kennelID/camera",
                                  MqttQos.exactlyOnce,
                                  builder.payload!);
                              print('MQTT message sent to turn off the camera');
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
                  );
                },
                itemCount: widget.reservations.length),
          ),
        ],
      ),
    );
  }
}
