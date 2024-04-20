import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDisplayPage extends StatefulWidget {
  final String eventId;

  const AdminDisplayPage({super.key, required this.eventId});

  @override
  // ignore: library_private_types_in_public_api
  _AdminDisplayPageState createState() => _AdminDisplayPageState();
}

class _AdminDisplayPageState extends State<AdminDisplayPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('events').doc(widget.eventId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Event not found.'),
            );
          } else {
            final eventData = snapshot.data!;
            final eventName = eventData['event_name'] ?? 'Unnamed Event';
            final eventDesc = eventData['description'] ?? 'No description available';
            final eventStartTimestamp = eventData['start_datetime'] as Timestamp?;
            final eventEndTimestamp = eventData['end_datetime'] as Timestamp?;
            final eventStartDate = eventStartTimestamp != null ? eventStartTimestamp.toDate() : DateTime.now();
            final eventEndDate = eventEndTimestamp != null ? eventEndTimestamp.toDate() : DateTime.now();

            final dateFormat = DateFormat.yMMMd();
            final formattedStartDate = dateFormat.format(eventStartDate);
            final formattedStartTime = DateFormat('h:mm a').format(eventStartDate);
            final formattedEndDate = dateFormat.format(eventEndDate);
            final formattedEndTime = DateFormat('h:mm a').format(eventEndDate);

            final eventLoc = eventData['location'] ?? 'No location specified';

            String displayDate;
            if (eventStartDate.year == eventEndDate.year &&
                eventStartDate.month == eventEndDate.month &&
                eventStartDate.day == eventEndDate.day) {
              displayDate = formattedStartDate;
            } else {
              displayDate = '$formattedStartDate - $formattedEndDate';
            }

            final imageUrl = eventData['image_url'];

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Description: $eventDesc',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: $displayDate',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Time: $formattedStartTime - $formattedEndTime',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Location: $eventLoc',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
