import 'package:flutter/material.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

import 'home.dart';
import 'map.dart';

class Navigation extends StatefulWidget {
  final MqttServerClient client;
  const Navigation({super.key, required this.client});

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
                  )))
        ],
      ),
      bottomNavigationBar: NavigationBar(
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
      ),
      /*BottomAppBar(
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
      /*floatingActionButton: FloatingActionButton(
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,*/
      body: <Widget>[
        Home(
            onDogSelected: (int index) => setState(() {
                  selectedDog = index;
                })),
        Map(
          client: widget.client,
        ),
      ][currentPageIndex],
    );
  }
}
