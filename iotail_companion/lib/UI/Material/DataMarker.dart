import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class DataMarker extends Marker {
  const DataMarker({
    required this.data,
    required super.point,
    required super.child,
    super.height,
    super.width,
  });

  final Map data;
}

class DataMarkerPopup extends StatelessWidget {
  const DataMarkerPopup({super.key, required this.data});
  final Map data; // Data to show in the popup

  @override
  Widget build(BuildContext context) {
    String title = "Supermercato";
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
                onPressed: () {},
                icon: Icon(
                  Icons.pets,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                )),
            const SizedBox(
              width: 10,
            ),
            Flexible(
              child: Column(
                // Add a column to show the data
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
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
