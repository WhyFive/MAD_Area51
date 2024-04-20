import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_display.dart';

class FavoriteEventsPage extends StatelessWidget {
  final String userId;

  const FavoriteEventsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Events'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.data() == null) {
            // ignore: avoid_print
            print('No data available for user: $userId');
            return _buildNoFavoriteEventsMessage(); // Display message when there are no favorite events
          }

          final userData = snapshot.data!;
          final List<dynamic> favoriteEvents = userData['favorites'];

          // Check if there are no favorite events
          if (favoriteEvents.isEmpty) {
            // ignore: avoid_print
            print('No favorite events found for user: $userId');
            return _buildNoFavoriteEventsMessage(); // Display message when there are no favorite events
          }

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('events').get(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                // ignore: avoid_print
                print('Error fetching events: ${snapshot.error}');
                return Center(child: Text('Error fetching events: ${snapshot.error}'));
              }
              final List<QueryDocumentSnapshot> events = snapshot.data!.docs;
              if (events.isEmpty) {
                // ignore: avoid_print
                print('No events available');
                return _buildNoFavoriteEventsMessage(); // Display message when there are no events
              }
              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (BuildContext context, int index) {
                  final event = events[index];
                  if (!favoriteEvents.contains(event.id)) {
                    // ignore: avoid_print
                    print('Skipping event ${event.id} as it is not a favorite event');
                    return const SizedBox.shrink();
                  }
                  final eventName = event['event_name'];
                  final eventDescription = event['description'];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text(eventName),
                      subtitle: Text(eventDescription.substring(0, 50)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentDisplayPage(eventId: event.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Method to build the message when there are no favorite events
  Widget _buildNoFavoriteEventsMessage() {
    return const Center(
      child: Text('There are no favorite events.'),
    );
  }
}
