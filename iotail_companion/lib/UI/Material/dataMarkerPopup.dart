import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DataMarkerPopup extends StatelessWidget {
  const DataMarkerPopup(
      {super.key,
      required this.name,
      required this.isSuitable,
      required this.onReserve});
  final String name; // Name to show in the popup
  final bool
      isSuitable; // Boolean to check if the dog is suitable for the kennels inside the store
  final VoidCallback onReserve;

  void _showReservationDialog(context) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text(
                "Confirm reservation",
                textAlign: TextAlign.center,
              ),
              content: Text("Are you sure you want to book a kennel?"),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(
                    onPressed: () => context.pop(),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () {
                      onReserve();
                      context.pop();
                    },
                    child: const Text("Yes")),
              ],
            ));
  }

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
                onPressed: () =>
                    isSuitable ? _showReservationDialog(context) : null,
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
