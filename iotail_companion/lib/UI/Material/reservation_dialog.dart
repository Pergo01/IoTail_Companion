import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservationDialog extends StatefulWidget {
  const ReservationDialog({super.key});

  @override
  _ReservationDialog createState() => _ReservationDialog();
}

class _ReservationDialog extends State<ReservationDialog> {
  final int startHourMorning = 9; // Morning block starts at 9:00
  final int startHourAfternoon = 14; // Afternoon block starts at 14:00
  final int intervalsPerHour = 4; // 4 intervals per hour (00, 15, 30, 45)
  final int itemsPerPage = 20; // 5 rows * 4 columns

  late PageController _pageController;
  DateTime currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    // Check if the current time is after 13:45 today
    DateTime now = DateTime.now();
    DateTime afternoonStart = DateTime(now.year, now.month, now.day, 13, 45);

    // If it's after 13:45 today, set initialPage to 1 (afternoon); otherwise, start with 0 (morning)
    int initialPage = (now.isAfter(afternoonStart)) ? 1 : 0;

    // Initialize the PageController with the computed initialPage
    _pageController = PageController(initialPage: initialPage);

    // Listen to page changes and update the current date accordingly
    _pageController.addListener(() {
      int pageIndex = _pageController.page?.floor() ?? 0;
      setState(() {
        // Every 2 pages corresponds to one day
        currentDate = DateTime.now().add(Duration(days: pageIndex ~/ 2));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day header at the top with the current date
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            DateFormat("EEEE, MMMM d y")
                .format(currentDate), // Display the current date
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // PageView for horizontal scrolling between days
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, pageIndex) {
              // Check if it's morning or afternoon block
              bool isMorningBlock = (pageIndex % 2 == 0);
              int startHour =
                  isMorningBlock ? startHourMorning : startHourAfternoon;

              return GridView.builder(
                physics:
                    const NeverScrollableScrollPhysics(), // Disable internal scrolling
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 columns (15-minute intervals)
                  mainAxisSpacing: 0.0,
                  crossAxisSpacing: 0.0,
                  childAspectRatio: 1,
                ),
                itemCount:
                    itemsPerPage, // 20 items per page (5 rows * 4 columns)
                itemBuilder: (context, index) {
                  int hour = startHour + index ~/ intervalsPerHour;
                  int minute = (index % intervalsPerHour) * 15;
                  String timeLabel =
                      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                  int currTime = now.hour * 60 + now.minute;
                  int selectedTime = hour * 60 + minute;

                  return InkWell(
                    onTap: () {
                      if (now.year == currentDate.year &&
                          now.month == currentDate.month &&
                          now.day == currentDate.day &&
                          currTime >= selectedTime) {
                        return;
                      }
                      // Handle the time slot selection
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 1,
                        ),
                        color: (now.year == currentDate.year &&
                                now.month == currentDate.month &&
                                now.day == currentDate.day &&
                                currTime >= selectedTime)
                            ? Theme.of(context).colorScheme.onError
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          timeLabel, // Display the time slot (e.g., 09:00, 09:15, etc.)
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
