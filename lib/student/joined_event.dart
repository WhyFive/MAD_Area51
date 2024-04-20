import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'student_display.dart';

enum FilterOption { all, today, upcoming, past }

class JoinedEventsPage extends StatefulWidget {
  final String userId;

  const JoinedEventsPage({super.key, required this.userId});

  @override
  // ignore: library_private_types_in_public_api
  _JoinedEventsPageState createState() => _JoinedEventsPageState();
}

class _JoinedEventsPageState extends State<JoinedEventsPage> {
  FilterOption _selectedFilter = FilterOption.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Joined Events'),
        actions: [
          DropdownButton<FilterOption>(
            value: _selectedFilter,
            icon: const Icon(Icons.filter_alt),
            onChanged: (FilterOption? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedFilter = newValue;
                });
              }
            },
            items: FilterOption.values.map((option) {
              String text = '';
              switch (option) {
                case FilterOption.all:
                  text = 'All';
                  break;
                case FilterOption.today:
                  text = 'Today';
                  break;
                case FilterOption.upcoming:
                  text = 'Upcoming';
                  break;
                case FilterOption.past:
                  text = 'Past';
                  break;
              }
              return DropdownMenuItem<FilterOption>(
                value: option,
                child: Text(text),
              );
            }).toList(),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final userData = snapshot.data;
            if (userData == null || !userData.exists) {
              return const Center(child: Text('User not found'));
            } else {
              final joinedEvents = userData['events'] as List<dynamic>? ?? [];
              if (joinedEvents.isEmpty) {
                return const Center(child: Text('You have not joined any events yet.'));
              } else {
                return ListView.builder(
                  itemCount: joinedEvents.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('events').doc(joinedEvents[index]).get(),
                      builder: (context, eventSnapshot) {
                        if (eventSnapshot.connectionState == ConnectionState.waiting) {
                          return const ListTile(title: Text('Loading...'));
                        } else if (eventSnapshot.hasError) {
                          return const ListTile(title: Text('Error loading event'));
                        } else {
                          final eventData = eventSnapshot.data;
                          if (eventData == null || !eventData.exists) {
                            return const ListTile(title: Text('Event not found'));
                          } else {
                            final eventName = eventData['event_name'] ?? 'Unnamed Event';
                            final eventDesc = eventData['description'] ?? 'No description available';
                            final eventStartTimestamp = eventData['start_datetime'] as Timestamp?;
                            final eventStartDate = eventStartTimestamp != null ? eventStartTimestamp.toDate() : DateTime.now();
                            final formattedStartDate = DateFormat.yMMMd().format(eventStartDate);
                            final formattedStartTime = DateFormat('h:mm a').format(eventStartDate);

                            if (_shouldShowEvent(eventStartDate)) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StudentDisplayPage(eventId: eventData.id),
                                    ),
                                  );
                                },
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(eventName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Text(
                                          eventDesc.length <= 50 ? eventDesc : eventDesc.substring(0, 50) + '...',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Date: $formattedStartDate',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          'Time: $formattedStartTime',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return const SizedBox.shrink(); // Hidden if filtered out
                            }
                          }
                        }
                      },
                    );
                  },
                );
              }
            }
          }
        },
      ),
    );
  }

  bool _shouldShowEvent(DateTime eventDate) {
    DateTime now = DateTime.now();
    switch (_selectedFilter) {
      case FilterOption.all:
        return true;
      case FilterOption.today:
        return eventDate.year == now.year && eventDate.month == now.month && eventDate.day == now.day;
      case FilterOption.upcoming:
        return eventDate.isAfter(now);
      case FilterOption.past:
        return eventDate.isBefore(now);
    }
  }
}
