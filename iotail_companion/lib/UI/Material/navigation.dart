import 'package:flutter/material.dart';

import 'home.dart';
import 'map.dart';

class Navigation extends StatefulWidget {
  const Navigation({Key? key}) : super(key: key);

  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("IoTail"),
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
      body: const <Widget>[
        Home(),
        Map(),
      ][currentPageIndex],
    );
  }
}
