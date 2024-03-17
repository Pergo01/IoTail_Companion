import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

import '../../center_button/model/bottom_bar_center_model.dart';
import '../../center_button/widgets/animated_button.dart';
import '../../center_button/widgets/floating_center_button.dart';
import '../../center_button/widgets/floating_center_button_child.dart';
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
  int currentPageIndex = 0;
  int selectedDog = 0;
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
      bottomNavigationBar: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 300),
        child: Stack(alignment: Alignment.bottomCenter, children: [
          Card(
            margin: EdgeInsets.only(
                left: (width / 4) + 10, right: (width / 4) + 10, bottom: 20),
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                      currentPageIndex == 0 ? Icons.home : Icons.home_outlined,
                    ),
                  ),
                ),
                IconButton(
                  iconSize: 24,
                  onPressed: () => {},
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
          Positioned(
            top: 5,
            child: AnimatedButton(
              bottomBarCenterModel: BottomBarCenterModel(
                centerBackgroundColor: Theme.of(context).colorScheme.primary,
                centerIcon: FloatingCenterButton(
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Image.asset(dogPicture[selectedDog])),
                  ),
                ),
                centerIconChild: [
                  FloatingCenterButtonChild(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Image.asset(dogPicture[0])),
                    ),
                    onTap: () {
                      setState(() {
                        selectedDog = 0;
                      });
                    },
                  ),
                  FloatingCenterButtonChild(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Image.asset(dogPicture[1])),
                    ),
                    onTap: () {
                      setState(() {
                        selectedDog = 1;
                      });
                    },
                  ),
                  const FloatingCenterButtonChild(
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
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
