import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

import 'home.dart';
import 'map.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> with TickerProviderStateMixin {
  static const Duration duration = Duration(milliseconds: 300);
  late final AnimationController controller;
  late final MenuController menuController = MenuController();
  int currentPageIndex = 0;
  int selectedDog = 0;
  bool isExpanded = false;
  List<String> dogPicture = [
    "assets/default_cane.jpeg",
    "assets/default_cane_2.jpeg"
  ];
  final MqttServerClient client =
      MqttServerClient("mqtt.eclipseprojects.io", "");

  @override
  void initState() {
    client.connect('IoTail_client');
    controller = AnimationController(
      duration: duration,
      vsync: this,
    );
    super.initState();
  }

  @override
  void dispose() {
    client.disconnect();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("IoTail"),
      ),
      bottomNavigationBar: Stack(alignment: Alignment.bottomCenter, children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 172),
          child: Card(
            /* margin: EdgeInsets.only(
                  left: (width / 4) + 10, right: (width / 4) + 10, bottom: 20), */
            margin:
                EdgeInsets.symmetric(vertical: 20, horizontal: (width / 4) + 4),
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        currentPageIndex == 0
                            ? Icons.home
                            : Icons.home_outlined,
                      ),
                    ),
                  ),
                  IconButton(
                    iconSize: 24,
                    onPressed: null,
                    icon: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        foregroundImage: AssetImage(dogPicture[selectedDog]),
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
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        currentPageIndex == 1 ? Icons.map : Icons.map_outlined,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 20,
          //left: (width / 2) - 24,
          //right: (width / 2) + 24,
          child: MenuAnchor(
            controller: menuController,
            alignmentOffset: const Offset(0, -57.5),
            style: MenuStyle(
                maximumSize:
                    MaterialStateProperty.all(const Size(double.infinity, 200)),
                elevation: MaterialStateProperty.all(1),
                backgroundColor: MaterialStateProperty.all(
                    Theme.of(context).colorScheme.primary),
                visualDensity: VisualDensity.compact,
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)))),
            menuChildren: [
              for (var i = dogPicture.length - 1; i >= 0; i--)
                IconButton(
                  iconSize: 24,
                  onPressed: () => setState(() {
                    selectedDog = i;
                    menuController.close();
                  }),
                  icon: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      foregroundImage: AssetImage(dogPicture[i]),
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
                      color: Theme.of(context).colorScheme.onPrimary, width: 2),
                ),
                child: IconButton(
                    iconSize: 24,
                    color: Theme.of(context).colorScheme.onPrimary,
                    alignment: Alignment.center,
                    onPressed: () => setState(() {
                          menuController.close();
                        }),
                    icon: const Icon(Icons.add)),
              )
            ],
            builder: (BuildContext context, MenuController menuController,
                Widget? child) {
              return IconButton(
                iconSize: 24,
                onPressed: () {
                  if (menuController.isOpen) {
                    menuController.close();
                  } else {
                    menuController.open();
                  }
                },
                icon: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundImage: AssetImage(dogPicture[selectedDog]),
                  ),
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
            ),
          ),
          SlideTransition(
            position: controller.drive(
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ),
            ),
            child: Map(
              client: client,
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
  }
}
