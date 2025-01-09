import 'package:flutter/material.dart';
import 'package:iotail_companion/UI/Material/reservation_dialog.dart';

class DataMarkerPopup extends StatelessWidget {
  const DataMarkerPopup(
      {super.key, required this.name, required this.isSuitable});
  final String name; // Name to show in the popup
  final bool
      isSuitable; // Boolean to check if the dog is suitable for the kennels inside the store

  @override
  Widget build(BuildContext context) {
    return Card(
      // Return a card with the data
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width -
                16), // Set the maximum width of the container to the screen width minus 16
        padding: const EdgeInsets.only(top: 8, bottom: 8, right: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                onPressed: () => isSuitable
                    ? showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: const Text(
                                "Book a kennel",
                                textAlign: TextAlign.center,
                              ),
                              content: SizedBox(
                                  width: double.maxFinite,
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  child: const ReservationDialog()),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text("Chiudi"))
                              ],
                            ))
                    : null,
                icon: Icon(
                  isSuitable ? Icons.calendar_month : Icons.event_busy,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                )),
            // const SizedBox(
            //   width: 5,
            // ),
            Flexible(
              child: Column(
                // Add a column to show the data
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    name,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
