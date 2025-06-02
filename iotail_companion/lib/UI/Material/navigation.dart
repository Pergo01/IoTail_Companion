import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'dart:typed_data';
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

final homePageKey = GlobalKey();
final menuButtonKey = GlobalKey();
final mapNavBarButtonKey = GlobalKey();
final userEditButtonKey = GlobalKey();
final unlockKennelFABKey = GlobalKey();
final mapPageKey = GlobalKey();
final homePageButtonKey = GlobalKey();

class Navigation extends StatefulWidget {
  final String? ip;
  final String? token;
  final String? userID;

  const Navigation(
      {super.key, required this.ip, required this.token, required this.userID});

  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> with TickerProviderStateMixin {
  static const Duration duration = Duration(milliseconds: 300);
  late final AnimationController controller;
  late final AnimationController animateMenuController;
  late final MenuController menuController = MenuController();
  late ScrollController _scrollController;
  int currentPageIndex = 0;
  int selectedDog = 0;
  bool isOpen = false;
  late List<Uint8List?> dogPicture;
  late DataMarker selectedShop;
  late List<DataMarker> markersList;

  late Future<User> user;
  late Future<List<Store>> stores;
  late List<bool> isExpanded;
  late Future<List<Reservation>> prenotazioni;
  late Future<List<Breed>> breeds;
  late Future<MqttServerClient> MQTTClient;

  Future<User> getUser() async {
    final Map<String, dynamic> data =
        await requests.getUser(widget.ip!, widget.userID!, widget.token!);
    final Uint8List? profilePicture = await requests.getProfilePicture(
        widget.ip!, widget.userID!, widget.token!);
    data["ProfilePicture"] = profilePicture;
    for (Map dog in data["Dogs"]) {
      Uint8List? picture = await requests.getDogPicture(
          widget.ip!, widget.userID!, dog["DogID"], widget.token!);
      dog["Picture"] = picture;
    }
    User user = User.fromJson(data);
    if (selectedDog >= user.dogs.length) {
      selectedDog = 0;
    }
    return user;
  }

  Future<List<Reservation>> getReservations() async {
    var data = await requests.getReservations(
        widget.ip!, widget.userID!, widget.token!);
    isExpanded = List.filled(data.length, false);
    return data
        .map((reservation) => Reservation.fromJson(reservation))
        .toList();
  }

  Future<List<Store>> getStores() async {
    var data = await requests.getStores(widget.ip!, widget.token!);
    List<Store> tmp = [];
    for (var store in data) {
      tmp.add(Store.fromJson(store));
    }
    return tmp;
  }

  Future<String> reserveKennel(Map<String, dynamic> data) async {
    final Map response =
        await requests.reserve(widget.ip!, widget.token!, data);
    if (response["message"].contains("Failed")) {
      return response["message"];
    } else {
      setState(() {
        prenotazioni = getReservations();
      });
      return "Reservation was successful";
    }
  }

  Future<String> unlockKennel(Map<String, dynamic> data) async {
    final Map response =
        await requests.unlock_kennel(widget.ip!, widget.token!, data);
    if (response["message"].contains("Failed")) {
      return response["message"];
    } else if (response["message"].contains("Kennel")) {
      return response["message"];
    } else {
      setState(() {
        prenotazioni = getReservations();
      });
      return "Kennel was unlocked";
    }
  }

  Future<List<Breed>> getBreeds() async {
    var data = await requests.getBreeds(widget.ip!, widget.token!);
    List<Breed> tmp = [];
    for (var breed in data) {
      tmp.add(Breed.fromJson(breed));
    }
    return tmp;
  }

  Future<MqttServerClient> initializeClient() async {
    final MqttServerClient client =
        MqttServerClient(widget.ip!, widget.userID!);
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    final connMess = MqttConnectMessage()
        .withClientIdentifier(widget.userID!)
        .startClean(); // Non persistent session for testing
    client.connectionMessage = connMess;
    try {
      await client.connect();
    } on Exception catch (e) {
      print('Client exception - $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Mosquitto client connected');
    } else {
      print(
          'ERROR Mosquitto client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
      client.disconnect();
    }

    return client;
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    print('Client disconnection');
  }

  @override
  void initState() {
    super.initState();
    user = getUser();
    breeds = getBreeds();
    prenotazioni = getReservations();
    stores = getStores();
    MQTTClient = initializeClient();
    _scrollController = ScrollController();
    controller = AnimationController(
      duration: duration,
      vsync: this,
    );
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
    _showCoachMark();
  }

  @override
  void dispose() {
    MQTTClient.then((val) => val.disconnect());
    controller.dispose();
    animateMenuController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDog(int index) {
    _scrollController.animateTo(
      index * 342, // Adjust the value based on the width of each tile
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showCoachMark() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ShowCaseWidget.of(context).startShowCase([
        homePageKey,
        menuButtonKey,
        userEditButtonKey,
        unlockKennelFABKey,
        mapNavBarButtonKey,
        mapPageKey,
        homePageButtonKey
      ]);
    });
  }

  // Helper function to check if a store has a suitable kennel
  bool _isStoreSuitable(Store store, Dog dog, List<Reservation> reservations) {
    List<int?> storeIDs = reservations.map((reservation) {
      if (reservation.dogID == dog.dogID) {
        return reservation.storeID;
      }
    }).toList();
    if (storeIDs.contains(store.id)) {
      return false;
    }
    for (var kennel in store.kennels) {
      if (!kennel.booked &&
          !kennel.occupied &&
          _sizeFits(kennel.size, dog.size)) {
        return true;
      }
    }
    return false;
  }

  // Helper function to check if the kennel size fits the dog size
  bool _sizeFits(String kennelSize, String dogSize) {
    const sizeOrder = {"Small": 0, "Medium": 1, "Large": 2};
    return sizeOrder[kennelSize]! >= sizeOrder[dogSize]!;
  }

  List<DataMarker> _getMarkersList(
      List<Store> stores, User user, List<Reservation> reservations) {
    List<DataMarker> markersList;
    if (user.dogs.isEmpty) {
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
      ).toList();
    } else {
      dogPicture = user.dogs.map((dog) => dog.picture).toList();
      Dog dog = user.dogs[selectedDog];
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
      ).toList();
    }
    return markersList;
  }

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
              ),
              TextField(
                keyboardType: TextInputType.number,
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
              TextButton(
                  onPressed: () async {
                    if (kennelID == -1 || unlockCode == -1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Please fill all fields"),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      context.pop();
                      return;
                    }
                    Map<String, dynamic> data = {
                      "dogID": user.dogs[selectedDog].dogID,
                      "userID": widget.userID,
                      "dog_size": user.dogs[selectedDog].size,
                      "kennelID": kennelID,
                      "unlockCode": unlockCode,
                    };
                    final response = await unlockKennel(data);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    setState(() {
                      prenotazioni = getReservations();
                      stores = getStores();
                      markersList =
                          _getMarkersList(storesList, user, reservations);
                    });
                    context.pop();
                  },
                  child: Text("Unlock")),
              TextButton(onPressed: () => context.pop(), child: Text("Cancel"))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    final isDarkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return FutureBuilder(
      future: Future.wait([user, prenotazioni, stores, breeds, MQTTClient]),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          dogPicture = [];
          markersList = _getMarkersList(
              snapshot.data![2] as List<Store>,
              snapshot.data![0] as User,
              snapshot.data![1] as List<Reservation>);
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
                ).createShader(bounds),
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
                          "user": snapshot.data![0],
                          "ip": widget.ip,
                          "token": widget.token,
                          "onEdit": () async {
                            setState(() {
                              user = getUser();
                            });
                          }
                        });
                      },
                      icon: ((snapshot.data![0] as User)
                                  .profilePicture!
                                  .isEmpty) ||
                              (snapshot.data![0] as User).profilePicture == null
                          ? Icon(Icons.account_circle_outlined,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer)
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
                              ),
                            )),
                ),
              ],
            ),
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
                          right: width / 4 + 12)
                      : EdgeInsets.symmetric(
                          vertical: 20, horizontal: width / 4 + 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: isDarkTheme
                          ? BorderSide(
                              color: Theme.of(context).colorScheme.primary)
                          : BorderSide.none),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 172),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Showcase(
                          key: homePageButtonKey,
                          titleAlignment: Alignment.centerLeft,
                          title: "Home screen",
                          titleTextStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          descriptionAlignment: Alignment.centerLeft,
                          description:
                              "Now, let's go back to the home screen. It's time to add your first dog.",
                          descTextStyle: Theme.of(context).textTheme.bodyMedium,
                          tooltipBackgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          targetBorderRadius: BorderRadius.circular(30),
                          disposeOnTap: false,
                          onTargetClick: () {
                            if (currentPageIndex == 1) {
                              setState(() {
                                controller.reverse();
                                currentPageIndex = 0;
                              });
                            }
                            ShowCaseWidget.of(context).next();
                          },
                          tooltipActions: [
                            TooltipActionButton(
                                type: TooltipDefaultActionType.previous,
                                leadIcon: const ActionButtonIcon(
                                  icon: Icon(
                                    Icons.arrow_back_ios,
                                    size: 16,
                                  ), // Icon
                                ), // ActionButtonIcon
                                name: "Previous",
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: isDarkTheme
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary),
                                onTap: () {
                                  if (currentPageIndex == 0) {
                                    setState(() {
                                      controller.forward();
                                      currentPageIndex = 1;
                                    });
                                  }
                                  ShowCaseWidget.of(context).previous();
                                }),
                            TooltipActionButton(
                                type: TooltipDefaultActionType.next,
                                name: "Finish",
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: isDarkTheme
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                            : Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer),
                                backgroundColor: isDarkTheme
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                onTap: () {
                                  if (currentPageIndex == 1) {
                                    setState(() {
                                      controller.reverse();
                                      currentPageIndex = 0;
                                    });
                                  }
                                  ShowCaseWidget.of(context).next();
                                }),
                          ],
                          child: IconButton(
                            iconSize: 24,
                            onPressed: () {
                              if (currentPageIndex == 1) {
                                setState(() {
                                  controller.reverse();
                                  currentPageIndex = 0;
                                });
                              }
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: currentPageIndex == 0
                                    ? Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                currentPageIndex == 0
                                    ? Icons.home
                                    : Icons.home_outlined,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                            ),
                          ),
                        ),
                        Showcase(
                          key: menuButtonKey,
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
                                                    "assets/default_cane.jpeg")
                                                : Image.memory(dogPicture[
                                                        selectedDog]!)
                                                    .image,
                                          )
                                        : const CircleAvatar(
                                            backgroundColor:
                                                Colors.transparent),
                                  )
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
                                                user = getUser();
                                              });
                                            }
                                          });
                                        },
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                      ),
                                    ),
                                  ),
                            onCanceled: () {
                              setState(() {
                                isOpen = false;
                              });
                            },
                            onOpened: () {
                              setState(() {
                                isOpen = true;
                              });
                            },
                            onSelected: (int index) {
                              if (index == -999) {
                                return;
                              }
                              if (index >= 0) {
                                setState(() {
                                  selectedDog = index;
                                  markersList = _getMarkersList(
                                      snapshot.data![2] as List<Store>,
                                      snapshot.data![0] as User,
                                      snapshot.data![1] as List<Reservation>);
                                  isOpen = false;
                                });
                                _scrollToSelectedDog(index);
                              } else {
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
                                      user = getUser();
                                    });
                                  }
                                });
                                setState(() {
                                  selectedDog = 0;
                                  isOpen = false;
                                });
                              }
                            },
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
                                                    maxHeight:
                                                        dogPicture.length > 3
                                                            ? 180
                                                            : dogPicture
                                                                    .length *
                                                                60.0,
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
                                                      int i =
                                                          dogPicture.length -
                                                              index -
                                                              1;
                                                      return InkWell(
                                                        onTap: () {
                                                          context.pop(i);
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
                                                            ),
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
                                                                  )
                                                                : CircleAvatar(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .transparent,
                                                                    foregroundImage:
                                                                        Image.memory(dogPicture[i]!)
                                                                            .image,
                                                                  ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                          if (dogPicture.isNotEmpty)
                                            Divider(
                                                height: 8,
                                                thickness: 1,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer),
                                        ],
                                      ),
                                    )),
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
                        Showcase(
                          key: mapNavBarButtonKey,
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
                              // Prima completa la transizione
                              setState(() {
                                controller.forward().then((_) {
                                  currentPageIndex = 1;
                                  // Solo dopo la transizione completa, avanza nello showcase
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    ShowCaseWidget.of(context).next();
                                  });
                                });
                              });
                            }
                          },
                          tooltipActions: [
                            TooltipActionButton(
                              type: TooltipDefaultActionType.previous,
                              leadIcon: const ActionButtonIcon(
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  size: 16,
                                ), // Icon
                              ), // ActionButtonIcon
                              name: "Previous",
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: isDarkTheme
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary),
                            ),
                            TooltipActionButton(
                                type: TooltipDefaultActionType.next,
                                name: "Next",
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: isDarkTheme
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                            : Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer),
                                backgroundColor: isDarkTheme
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                onTap: () {
                                  if (currentPageIndex == 0) {
                                    // Prima completa la transizione
                                    setState(() {
                                      controller.forward().then((_) {
                                        currentPageIndex = 1;
                                        // Solo dopo la transizione completa, avanza nello showcase
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          ShowCaseWidget.of(context).next();
                                        });
                                      });
                                    });
                                  } else {
                                    ShowCaseWidget.of(context).next();
                                  }
                                }),
                          ],
                          child: IconButton(
                            iconSize: 24,
                            onPressed: () {
                              if (currentPageIndex == 0) {
                                setState(() {
                                  controller.forward();
                                  currentPageIndex = 1;
                                });
                              }
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: currentPageIndex == 1
                                    ? Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                currentPageIndex == 1
                                    ? Icons.map
                                    : Icons.map_outlined,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
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
            body: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  user = getUser();
                  prenotazioni = getReservations();
                  stores = getStores();
                  markersList = _getMarkersList(
                      snapshot.data![2] as List<Store>,
                      snapshot.data![0] as User,
                      snapshot.data![1] as List<Reservation>);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Refresh completed"),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Stack(
                children: [
                  SlideTransition(
                    position: controller.drive(
                      Tween<Offset>(
                        begin: Offset.zero,
                        end: const Offset(-1, 0),
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
                            selectedDog = index;
                          });
                          _scrollToSelectedDog(index);
                        },
                        scrollController: _scrollController,
                        onDogUpdated: () {
                          setState(() {
                            user = getUser();
                            dogPicture = (snapshot.data![0] as User)
                                .dogs
                                .map((dog) => dog.picture)
                                .toList();
                          });
                        },
                        onReservationsUpdated: () {
                          setState(() {
                            prenotazioni = getReservations();
                            stores = getStores();
                            markersList = _getMarkersList(
                                snapshot.data![2] as List<Store>,
                                snapshot.data![0] as User,
                                snapshot.data![1] as List<Reservation>);
                          });
                        },
                        user: snapshot.data![0] as User,
                        breeds: snapshot.data![3] as List<Breed>,
                        reservations: snapshot.data![1] as List<Reservation>,
                        shops: snapshot.data![2] as List<Store>,
                        client: snapshot.data![4] as MqttServerClient,
                      ),
                    ),
                  ),
                  SlideTransition(
                    position: controller.drive(
                      Tween<Offset>(
                        begin: const Offset(1, 0),
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
                          "This is the map screen. Here, you can see all the stores that have available kennels.",
                      descTextStyle: Theme.of(context).textTheme.bodyMedium,
                      tooltipBackgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      tooltipActions: [
                        TooltipActionButton(
                            type: TooltipDefaultActionType.previous,
                            leadIcon: const ActionButtonIcon(
                              icon: Icon(
                                Icons.arrow_back_ios,
                                size: 16,
                              ), // Icon
                            ), // ActionButtonIcon
                            name: "Previous",
                            textStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: isDarkTheme
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .primary),
                            onTap: () {
                              if (currentPageIndex == 1) {
                                setState(() {
                                  controller.reverse();
                                  currentPageIndex = 0;
                                });
                              }
                              ShowCaseWidget.of(context).previous();
                            }),
                        TooltipActionButton(
                            type: TooltipDefaultActionType.next,
                            name: "Next",
                            textStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: isDarkTheme
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer),
                            hideActionWidgetForShowcase: [
                              mapNavBarButtonKey
                            ], // hide on last showcase
                            backgroundColor: isDarkTheme
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                            onTap: ShowCaseWidget.of(context).next),
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
                          };
                          final response = await reserveKennel(data);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          setState(() {
                            prenotazioni = getReservations();
                            stores = getStores();
                            markersList = _getMarkersList(
                                snapshot.data![2] as List<Store>,
                                snapshot.data![0] as User,
                                snapshot.data![1] as List<Reservation>);
                          });
                        },
                        onRefreshKennels: () {
                          setState(() {
                            stores = getStores();
                            markersList = _getMarkersList(
                                snapshot.data![2] as List<Store>,
                                snapshot.data![0] as User,
                                snapshot.data![1] as List<Reservation>);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Kennels refreshed"),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                        snapshot.data![1] as List<Reservation>);
                  },
                  label: Text("Unlock Kennel")),
            ),
          );
        } else if (snapshot.hasError) {
          String msg = snapshot.error.toString();
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
                ).createShader(bounds),
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
            body: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  user = getUser();
                  prenotazioni = getReservations();
                  stores = getStores();
                  markersList = _getMarkersList(
                      snapshot.data![2] as List<Store>,
                      snapshot.data![0] as User,
                      snapshot.data![1] as List<Reservation>);
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
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                setState(() {
                  user = getUser();
                  prenotazioni = getReservations();
                  stores = getStores();
                  markersList = _getMarkersList(
                      snapshot.data![2] as List<Store>,
                      snapshot.data![0] as User,
                      snapshot.data![1] as List<Reservation>);
                });
              },
              child: Icon(Icons.refresh),
            ),
          );
        }
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
              ).createShader(bounds),
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
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
