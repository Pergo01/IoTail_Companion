import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  final Function(int) onDogSelected;
  const Home({super.key, required this.onDogSelected});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  Map<String, String> cani = {
    "Fido": "Golden Retriever",
    "Fuffi": "Dobbermann",
  };
  List<String> dogPicture = [
    "assets/default_cane.jpeg",
    "assets/default_cane_2.jpeg"
  ];

  int selectedDog = 0;

  List<String> prenotazioni = ["Casa 1", "Casa 2"];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            "Cani:",
            style: TextStyle(fontSize: 40),
          ),
          SizedBox(
            height: 150,
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: cani.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                  radius: 5,
                  onTap: () {
                    widget.onDogSelected(index);
                    setState(() {
                      selectedDog = index;
                    });
                  },
                  child: Card(
                    elevation: selectedDog == index ? 5 : 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 300,
                        child: Row(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5))),
                              clipBehavior: Clip.hardEdge,
                              child: Image.asset(
                                dogPicture[index],
                                height: 100,
                                width: 100,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cani.keys.elementAt(index),
                                      style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    cani.values.elementAt(index),
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
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
                  return Card(
                    child: SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(prenotazioni[index],
                            style: const TextStyle(fontSize: 40)),
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
