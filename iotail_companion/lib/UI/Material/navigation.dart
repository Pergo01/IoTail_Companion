import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

import 'package:iotail_companion/util/dataMarker.dart';
import 'package:iotail_companion/util/store.dart';
import 'home.dart';
import 'map.dart';
import 'package:iotail_companion/util/requests.dart' as requests;
import 'package:iotail_companion/util/user.dart';

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
  int currentPageIndex = 0;
  int selectedDog = 0;
  bool isOpen = false;
  List<String> dogPicture = [
    "assets/default_cane.jpeg",
    "assets/default_cane_2.jpeg"
  ];
  final MqttServerClient client =
      MqttServerClient("mqtt.eclipseprojects.io", "");

  List cani = [];
  late Future<User> user;
  late Future<List<Store>> stores;
  late FlutterSecureStorage storage;
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );
  late List<bool> isExpanded;
  late Future<List> prenotazioni;

  Future<User> getUser() async {
    Map<String, dynamic> data =
        await requests.getUser(widget.ip!, widget.userID!, widget.token!);
    return User.fromJson(data);
  }

  Future<List> getReservations() async {
    var data = await requests.getReservations(
        widget.ip!, widget.userID!, widget.token!);
    isExpanded = List.filled(data.length, false);
    return data;
  }

  Future<List<Store>> getStores() async {
    var data = await requests.getStores(widget.ip!, widget.token!);
    List<Store> tmp = [];
    for (var store in data) {
      tmp.add(Store.fromJson(store));
    }
    return tmp;
  }

  @override
  void initState() {
    super.initState();
    storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    user = getUser();
    prenotazioni = getReservations();
    stores = getStores();
    client.connect('IoTail_app');
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
  }

  @override
  void dispose() {
    client.disconnect();
    controller.dispose();
    animateMenuController.dispose();
    super.dispose();
  }

  // Helper function to check if a store has a suitable kennel
  bool _isStoreSuitable(Store store, String dogSize) {
    for (var kennel in store.kennels) {
      if (!kennel.booked &&
          !kennel.occupied &&
          _sizeFits(kennel.size, dogSize)) {
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

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final isDarkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return FutureBuilder(
      future: Future.wait([user, prenotazioni, stores]),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<DataMarker> markersList;
          if ((snapshot.data![0] as User).dogs.isEmpty) {
            markersList = (snapshot.data![2] as List<Store>).map(
              (store) {
                Color color;
                bool isSuitable = true;
                color = Theme.of(context).colorScheme.primary;
                return DataMarker(
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
          } else {
            String dogSize = (snapshot.data![0] as User).dogs[selectedDog].size;
            markersList = (snapshot.data![2] as List<Store>).map(
              (store) {
                Color color;
                bool isSuitable = _isStoreSuitable(store, dogSize);
                if (isSuitable) {
                  color = Theme.of(context).colorScheme.primary;
                } else {
                  color = Colors.red;
                }
                return DataMarker(
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
                IconButton(
                  onPressed: () {
                    context.push("/User", extra: snapshot.data![0]);
                  },
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              ],
            ),
            bottomNavigationBar:
                Stack(alignment: Alignment.bottomCenter, children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 172),
                child: Card(
                  margin: EdgeInsets.symmetric(
                      vertical: 20, horizontal: (width / 4) + 4),
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
                        IconButton(
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
                        IconButton(
                          iconSize: 24,
                          onPressed: null,
                          icon: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              /* border: Border.all(
                            width: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ), */
                            ),
                            child: const CircleAvatar(
                              backgroundColor: Colors.transparent,
                              //foregroundImage: AssetImage(dogPicture[selectedDog]),
                            ),
                          ),
                        ),
                        IconButton(
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
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 18,
                child: MenuAnchor(
                  onOpen: animateMenuController.forward,
                  onClose: animateMenuController.reset,
                  controller: menuController,
                  alignmentOffset: const Offset(0, -56.5),
                  style: MenuStyle(
                      maximumSize: WidgetStateProperty.all(
                          const Size(double.infinity, 200)),
                      elevation: WidgetStateProperty.all(1),
                      backgroundColor: WidgetStateProperty.all(Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5)),
                      visualDensity: VisualDensity.compact,
                      shape: WidgetStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)))),
                  menuChildren: [
                    FadeTransition(
                      opacity: animateMenuController,
                      child: Column(
                        children: [
                          for (var i = dogPicture.length - 1; i >= 0; i--)
                            Animate(
                              effects: [
                                SlideEffect(
                                    begin: const Offset(0, 1),
                                    end: const Offset(0, 0),
                                    duration: duration,
                                    curve: Curves.bounceInOut,
                                    delay: Duration(
                                        milliseconds:
                                            (dogPicture.length - i) * 100)),
                              ],
                              child: IconButton(
                                iconSize: 24,
                                onPressed: () {
                                  if (animateMenuController.status
                                      case AnimationStatus.forward ||
                                          AnimationStatus.completed) {
                                    animateMenuController.reverse();
                                    setState(() {
                                      selectedDog = i;
                                      isOpen = false;
                                    });
                                  }
                                },
                                icon: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      width: 2,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    foregroundImage: AssetImage(dogPicture[i]),
                                  ),
                                ),
                              ),
                            ),
                          Container(
                            height: 45,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  width: 2),
                            ),
                            child: IconButton(
                                iconSize: 24,
                                color: Theme.of(context).colorScheme.onPrimary,
                                alignment: Alignment.center,
                                onPressed: () {
                                  if (animateMenuController.status
                                      case AnimationStatus.forward ||
                                          AnimationStatus.completed) {
                                    animateMenuController.reverse();
                                    setState(() {
                                      isOpen = false;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.add)),
                          )
                        ],
                      ),
                    ),
                  ],
                  builder: (BuildContext context, MenuController menuController,
                      Widget? child) {
                    return IconButton(
                      iconSize: 24,
                      onPressed: () {
                        if (animateMenuController.status
                            case AnimationStatus.forward ||
                                AnimationStatus.completed) {
                          animateMenuController.reverse();
                          setState(() {
                            isOpen = false;
                          });
                        } else {
                          animateMenuController.forward();
                          setState(() {
                            isOpen = true;
                          });
                        }
                        /*if (menuController.isOpen) {
                      //menuController.close();
                      setState(() {
                        isOpen = false;
                      });
                    } else {
                      //menuController.open();
                      setState(() {
                        isOpen = true;
                      });
                    }*/
                      },
                      icon: Container(
                        decoration: !isOpen || !menuController.isOpen
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : const BoxDecoration(shape: BoxShape.circle),
                        child: !isOpen || !menuController.isOpen
                            ? CircleAvatar(
                                backgroundColor: Colors.transparent,
                                foregroundImage:
                                    AssetImage(dogPicture[selectedDog]),
                              )
                            : const CircleAvatar(
                                backgroundColor: Colors.transparent),
                      ),
                    );
                  },
                ),
              ),
            ]),
            body: Stack(
              children: [
                SlideTransition(
                  position: controller.drive(
                    Tween<Offset>(
                      begin: Offset.zero,
                      end: const Offset(-1, 0),
                    ),
                  ),
                  child: Home(
                    selectedDog: selectedDog,
                    onDogSelected: (int index) {
                      setState(() {
                        selectedDog = index;
                      });
                    },
                    user: snapshot.data![0] as User,
                    reservations: snapshot.data![1] as List,
                  ),
                ),
                SlideTransition(
                  position: controller.drive(
                    Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ),
                  ),
                  child: OSMMap(
                    client: client,
                    markerslist: markersList,
                  ),
                ),
              ],
            ),
            floatingActionButton: currentPageIndex == 1
                ? FloatingActionButton.extended(
                    onPressed: () => context.push("/Booking", extra: client),
                    label: const Text("Vai a Booking"))
                : null,
          );
        } else if (snapshot.hasError) {
          return const Text("Error fetching data");
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
