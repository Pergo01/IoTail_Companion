import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:slide_countdown/slide_countdown.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:iotail_companion/util/user.dart';
import 'package:iotail_companion/util/requests.dart' as requests;

class Home extends StatefulWidget {
  final Function(int) onDogSelected;
  final int selectedDog;
  final User user;
  final List reservations;
  final List shops;
  final ScrollController scrollController;
  final VoidCallback onDogUpdated;
  final VoidCallback onReservationsUpdated;

  const Home(
      {super.key,
      required this.selectedDog,
      required this.onDogSelected,
      required this.onReservationsUpdated,
      required this.user,
      required this.reservations,
      required this.shops,
      required this.scrollController,
      required this.onDogUpdated});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  late String? ip;
  late String name;
  late String phone;
  late FlutterSecureStorage storage;

  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  late List<bool> isExpanded;
  late WebViewController webController;
  bool editMode = false;

  Future<void> setup() async {
    ip = await storage.read(key: "ip");
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('http:$ip:8090/camera_0'));
  }

  Future<bool> _showReservationCancelConfirmation(
      context, Map reservation) async {
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
                  ip!, token!, reservation["reservationID"]);
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

  @override
  void initState() {
    storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    setup();
    isExpanded = List.filled(widget.reservations.length, false);
    super.initState();
  }

  @override
  void didUpdateWidget(Home oldwidget) {
    super.didUpdateWidget(oldwidget);
    isExpanded = List.filled(widget.reservations.length, false);
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
                maxHeight: MediaQuery.of(context).size.height * 0.15),
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
                  onLongPress: () {
                    setState(() {
                      editMode = !editMode;
                    });
                  },
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Card(
                        elevation: widget.selectedDog == index ? 5 : 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: isDarkTheme
                                ? Border.all(
                                    color: widget.selectedDog == index
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    width: 1)
                                : null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 300,
                              child: Row(
                                children: [
                                  Container(
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5))),
                                    clipBehavior: Clip.hardEdge,
                                    child: widget.user.dogs[index].picture ==
                                                null ||
                                            widget.user.dogs[index].picture!
                                                .isEmpty
                                        ? Image.asset(
                                            "assets/default_cane.jpeg")
                                        : Image.memory(
                                            widget.user.dogs[index].picture!,
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.cover,
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
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                          widget.user.dogs
                                              .elementAt(index)
                                              .breed,
                                          style: const TextStyle(fontSize: 20),
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
                      if (editMode)
                        IconButton(
                            style: ButtonStyle(
                                // backgroundColor: WidgetStateProperty.all(
                                //     Colors.yellow.shade600),
                                shape: WidgetStateProperty.all(CircleBorder())),
                            // color: Colors.white,
                            onPressed: () async {
                              String? token = await storage.read(key: "token");
                              context.push(
                                "/Dog",
                                extra: {
                                  "dog": widget.user.dogs.elementAt(index),
                                  "userID": widget.user.userID,
                                  "ip": ip,
                                  "token": token,
                                  "onEdit": () {
                                    widget.onDogUpdated();
                                  }
                                },
                              );
                            },
                            icon: const Icon(Icons.edit)),
                    ],
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(
                  width: 8,
                );
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
              "Prenotazioni:",
              style: TextStyle(fontSize: 40),
            ),
          Expanded(
            child: ListView.separated(
                itemBuilder: (BuildContext context, int index) {
                  DateTime startTime = DateTime.fromMillisecondsSinceEpoch(
                      widget.reservations.elementAt(index)["timestamp"] * 1000);
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
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      _showReservationCancelConfirmation(
                          context, widget.reservations.elementAt(index));
                    },
                    key: Key(widget.reservations
                        .elementAt(index)["reservationID"]
                        .toString()),
                    confirmDismiss: (direction) {
                      return _showReservationCancelConfirmation(
                          context, widget.reservations.elementAt(index));
                    },
                    child: InkWell(
                      splashFactory: InkRipple.splashFactory,
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      onTap: () {
                        setState(() {
                          if (isExpanded[index] == true) {
                            isExpanded[index] = false;
                          } else {
                            isExpanded
                                .where((e) => e == true)
                                .forEach((element) {
                              isExpanded[isExpanded.indexOf(element)] = false;
                            });
                            isExpanded[index] = true;
                            webController.reload();
                          }
                        });
                      },
                      child: Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "Dog: ${widget.user.dogs.firstWhere((dog) => dog.dogID == widget.reservations.elementAt(index)["dogID"]).name}",
                                    style: const TextStyle(fontSize: 40)),
                                Text(
                                    "${widget.shops.firstWhere((shop) => shop.id == widget.reservations.elementAt(index)["storeID"]).name}, kennel: ${widget.reservations.elementAt(index)["kennelID"].toString().padLeft(3, '0')}",
                                    style: const TextStyle(fontSize: 20)),
                                SlideCountdown(
                                  duration: remainingTime,
                                  slideDirection: SlideDirection.up,
                                  separator: ":",
                                  separatorStyle: TextStyle(fontSize: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  style: const TextStyle(fontSize: 20),
                                  onDone: () async {
                                    Future.delayed(const Duration(seconds: 5),
                                        () {
                                      widget.onReservationsUpdated();
                                    });
                                  },
                                ),
                                if (isExpanded[index])
                                  SizedBox(
                                    height: 200,
                                    // Set a fixed height for the WebView
                                    child: WebViewWidget(
                                        controller: webController),
                                  ),
                                if (isExpanded[index])
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      IconButton(
                                          style: ButtonStyle(
                                              backgroundColor:
                                                  WidgetStateProperty.all(
                                                      Colors.red),
                                              shape: WidgetStateProperty.all(
                                                  RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
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
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(
                    height: 8,
                  );
                },
                itemCount: widget.reservations.length),
          )
        ],
      ),
    );
  }
}
