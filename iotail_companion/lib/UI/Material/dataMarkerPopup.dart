import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A widget that displays a popup with information about a shop.
class DataMarkerPopup extends StatelessWidget {
  final String name; // Name to show in the popup
  final bool
      isSuitable; // Boolean to check if the dog is suitable for the kennels inside the store
  final VoidCallback
      onReserve; // Callback function when the user sends the confirmation to reserve a kennel in that shop

  const DataMarkerPopup(
      {super.key,
      required this.name,
      required this.isSuitable,
      required this.onReserve});

  /// Shows a dialog to confirm the reservation of the kennel.
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
                    onPressed: () => context
                        .pop(), // Close the dialog without taking any action
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () {
                      onReserve(); // Call the callback function to reserve the kennel
                      context.pop(); // Close the dialog
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
            // Button to show the reservation dialog
            IconButton(
                style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      width: 1,
                    )),
                onPressed: () => isSuitable
                    ? _showReservationDialog(context)
                    : null, // Show the dialog only if the dog is suitable for the shop
                icon: Icon(
                  isSuitable
                      ? Icons.calendar_month
                      : Icons
                          .event_busy, // Show a calendar icon if the dog is suitable for the shop, otherwise show a busy icon
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                )),
            // Flexible widget to allow the text to take up the remaining space
            Flexible(
              child: Column(
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
