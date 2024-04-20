import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'calendar_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final DateTime date;
  final Color color;
  final String eventName; // Event name property

  Event(this.date, this.color, this.eventName);
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late CustomCalendarController _calendarController;
  final List<DateTime> _eventDates = [];
  DateTime? _selectedDate;
  late List<Event> _eventsForSelectedDay;

  @override
  void initState() {
    super.initState();
    _calendarController = CustomCalendarController();
    _eventsForSelectedDay = [];
    _fetchEventDates();
  }

  Future<void> _fetchEventDates() async {
    // Fetch event dates from Firestore
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .then((userDataSnapshot) {
        if (userDataSnapshot.exists) {
          List<dynamic> eventIds = userDataSnapshot.data()?['events'];
          if (eventIds.isNotEmpty) {
            // Fetch events for each event ID
            for (var eventId in eventIds) {
              FirebaseFirestore.instance
                  .collection('events')
                  .doc(eventId)
                  .get()
                  .then((eventSnapshot) {
                if (eventSnapshot.exists) {
                  Timestamp startTimestamp = eventSnapshot.data()?['start_datetime'];
                  Timestamp endTimestamp = eventSnapshot.data()?['end_datetime'];
                  DateTime startDate = startTimestamp.toDate();
                  DateTime endDate = endTimestamp.toDate();

                  DateTime eventStartDate = DateTime(startDate.year, startDate.month, startDate.day);
                  DateTime eventEndDate = DateTime(endDate.year, endDate.month, endDate.day);

                  // Retrieve event name
                  String eventName = eventSnapshot.data()?['event_name'];

                  setState(() {
                    _eventDates.add(eventStartDate);

                    if (eventStartDate != eventEndDate) {
                      int numberOfDays = eventEndDate.difference(eventStartDate).inDays;
                      for (int i = 1; i <= numberOfDays; i++) {
                        DateTime nextDate = eventStartDate.add(Duration(days: i));
                        _eventDates.add(nextDate);
                      }
                    }

                    _eventsForSelectedDay.add(Event(eventStartDate, Colors.blue, eventName));
                  });
                }
              });
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          Center(
            child: TableCalendar<Event>(
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
              },
              focusedDay: DateTime.now(),
              firstDay: DateTime.utc(2010),
              lastDay: DateTime.utc(2030),
              onDaySelected: _onDaySelected,
              eventLoader: _retrieveEventsForDay,
              selectedDayPredicate: (day) {
                return isSameDay(day, _selectedDate ?? DateTime.now());
              },
              calendarBuilders: CalendarBuilders(
                selectedBuilder: (context, date, events) {
                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      date.day.toString(),
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_selectedDate != null) // Only show the list if a date is selected
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _eventsForSelectedDay.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_eventsForSelectedDay[index].eventName),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  List<Event> _retrieveEventsForDay(DateTime day) {
    return _eventsForSelectedDay.where((event) => isSameDay(event.date, day)).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay; // Update the selected date
    });
  }
}
