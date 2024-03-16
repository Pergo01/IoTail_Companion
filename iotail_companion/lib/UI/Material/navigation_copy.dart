import 'package:flutter/material.dart';
import 'package:floating_bottom_bar/animated_bottom_navigation_bar.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

import 'home.dart';
import 'map.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> with TickerProviderStateMixin {
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
    super.initState();
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("IoTail"),
        actions: [
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          width: 2,
                          color: Theme.of(context).colorScheme.primary)),
                  child: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundImage: AssetImage(dogPicture[selectedDog]),
                  ))) /*CircleAvatar(
                backgroundColor: Colors.transparent,
                foregroundImage: AssetImage(dogPicture[selectedDog]),
                /*child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Image.asset(dogPicture[selectedDog],
                        fit: BoxFit.cover)*/
              )),*/
        ],
      ),
      /* bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: const [
          NavigationDestination(
              selectedIcon: Icon(Icons.home),
              icon: Icon(Icons.home_outlined),
              label: "Home"),
          NavigationDestination(
              selectedIcon: Icon(Icons.map),
              icon: Icon(Icons.map_outlined),
              label: "Map"),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ), */
      bottomNavigationBar: AnimatedBottomNavigationBar(
        barColor: Theme.of(context).colorScheme.primaryContainer,
        bottomBar: [
          BottomBarItem(
            icon: const Icon(Icons.home),
            iconSelected: Icon(
              Icons.home,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: "Home",
            onTap: (value) {
              setState(() {
                currentPageIndex = value;
              });
            },
          ),
          BottomBarItem(
            icon: const Icon(Icons.map),
            iconSelected: Icon(
              Icons.map,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: "Map",
            onTap: (value) {
              setState(() {
                currentPageIndex = value;
              });
            },
          ),
        ],
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
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
      /* BottomAppBar(
        notchMargin: 5,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                direction: Axis.vertical,
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      currentPageIndex = 0;
                    }),
                    icon: Icon(currentPageIndex == 0
                        ? Icons.home
                        : Icons.home_outlined),
                  ),
                  const Text("Home")
                ]),
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                direction: Axis.vertical,
                children: [
                  IconButton(
                      onPressed: () => setState(() {
                            currentPageIndex = 1;
                          }),
                      icon: Icon(currentPageIndex == 1
                          ? Icons.map
                          : Icons.map_outlined)),
                  const Text("Map")
                ]),
          ],
        ),
      ),*/

      /* floatingActionButton: FloatingActionButton(
        elevation: 0,
        onPressed: () {},
        shape: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.asset(dogPicture[currentPageIndex])),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, */
      body: <Widget>[
        Home(
            onDogSelected: (int index) => setState(() {
                  selectedDog = index;
                })),
        Map(
          client: client,
        ),
      ][currentPageIndex],
    );
  }
}
