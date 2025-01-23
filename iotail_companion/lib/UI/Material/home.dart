import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:iotail_companion/util/user.dart';

class Home extends StatefulWidget {
  final Function(int) onDogSelected;
  final int selectedDog;
  final User user;
  final List reservations;
  final ScrollController scrollController;
  final VoidCallback onDogUpdated;

  const Home(
      {super.key,
      required this.selectedDog,
      required this.onDogSelected,
      required this.user,
      required this.reservations,
      required this.scrollController,
      required this.onDogUpdated});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  List cani = [];
  late String? ip;
  late String name;
  late String phone;
  late FlutterSecureStorage storage;
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  List prenotazioni = [];
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

  @override
  void initState() {
    storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    cani = widget.user.dogs;
    setup();
    super.initState();
  }

  @override
  void didUpdateWidget(oldwidget) {
    super.didUpdateWidget(oldwidget);
    cani = widget.user.dogs;
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
            cani.isEmpty ? "Add a dog." : "Dogs:",
            style: TextStyle(fontSize: 40),
          ),
          SizedBox(
            height: 150,
            child: ListView.separated(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: cani.length,
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
                                        Text(cani.elementAt(index).name,
                                            style: const TextStyle(
                                                fontSize: 40,
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                          cani.elementAt(index).breed,
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
                                  "dog": cani.elementAt(index),
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
          if (prenotazioni.isNotEmpty)
            Divider(
              color: Theme.of(context).colorScheme.primary,
              thickness: 2,
            ),
          if (prenotazioni.isNotEmpty)
            const Text(
              "Prenotazioni:",
              style: TextStyle(fontSize: 40),
            ),
          Expanded(
            child: ListView.separated(
                itemBuilder: (BuildContext context, int index) {
                  return InkWell(
                    splashFactory: InkRipple.splashFactory,
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    onTap: () {
                      setState(() {
                        if (isExpanded[index] == true) {
                          isExpanded[index] = false;
                        } else {
                          isExpanded.where((e) => e == true).forEach((element) {
                            isExpanded[isExpanded.indexOf(element)] = false;
                          });
                          isExpanded[index] = true;
                          webController.reload();
                        }
                      });
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prenotazioni.elementAt(index)["ReservationID"],
                                style: const TextStyle(fontSize: 40)),
                            if (isExpanded[index])
                              SizedBox(
                                height: 200,
                                // Set a fixed height for the WebView
                                child: WebViewWidget(controller: webController),
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
                                                  Colors.yellow.shade600),
                                          shape: WidgetStateProperty.all(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5)))),
                                      color: Colors.white,
                                      onPressed: () {},
                                      icon: const Icon(Icons.edit)),
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
                                      onPressed: () {},
                                      icon: const Icon(Icons.delete)),
                                ],
                              )
                          ],
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
                itemCount: prenotazioni.length),
          )
        ],
      ),
    );
  }
}
