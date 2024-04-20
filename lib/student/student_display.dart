import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';


class StudentDisplayPage extends StatefulWidget {
  final String eventId;

  const StudentDisplayPage({super.key, required this.eventId});

  @override
  // ignore: library_private_types_in_public_api
  _EventDisplayPageState createState() => _EventDisplayPageState();
}

class _EventDisplayPageState extends State<StudentDisplayPage> {
  bool isFavorite = false;
  bool isJoined = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    isFavorite = false;
    _checkFavoriteStatus();
    _checkJoinedStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
              final imageUrl = eventData['image_url'];

              String displayDate;
              if (eventStartDate.year == eventEndDate.year &&
                  eventStartDate.month == eventEndDate.month &&
                  eventStartDate.day == eventEndDate.day) {
                displayDate = formattedStartDate;
              } else {
                displayDate = '$formattedStartDate - $formattedEndDate';
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null) ...[
                      SizedBox(
                        height: 200,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      eventName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: isJoined ? null : () => _confirmJoin(context),
            child: Container(
              width: 120,
              height: 60,
              decoration: BoxDecoration(
                color: isJoined ? Colors.grey : Colors.blue,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  isJoined ? 'Joined' : 'Join',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _toggleFavorite,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.black,
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _confirmJoin(BuildContext context) async {
    bool confirmJoin = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Join'),
        content: const Text('Do you want to join this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirmJoin) {
      await _joinEvent();
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

        final userDocSnapshot = await userDocRef.get();
        if (!userDocSnapshot.exists) {
          await userDocRef.set({'favorites': []});
        }

        final favorites = List<String>.from(userDocSnapshot.data()?['favorites'] ?? []);
        if (favorites.contains(widget.eventId)) {
          favorites.remove(widget.eventId);
        } else {
          favorites.add(widget.eventId);
        }

        await userDocRef.update({'favorites': favorites});

        setState(() {
          isFavorite = !isFavorite;
        });
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error toggling favorite status: $error');
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final userData = await userDoc.get();
        final favorites = userData.data()?['favorites'] as List<dynamic>? ?? [];

        setState(() {
          isFavorite = favorites.contains(widget.eventId);
        });
      }
    } catch (error) {
      // ignore: avoid_print
      print('Error checking favorite status: $error');
    }
  }

  Future<void> _checkJoinedStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final eventDoc = FirebaseFirestore.instance.collection('events').doc(widget.eventId);
        final eventData = await eventDoc.get();
        final participants = eventData.data()?['participants'] as List<dynamic>? ?? [];

        setState(() {
          isJoined = participants.contains(user.uid);
        });
      }
    } catch (error) {
      // ignore: avoid_print
      print('Error checking joined status: $error');
    }
  }

  Future<void> _joinEvent() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final eventDocRef = FirebaseFirestore.instance.collection('events').doc(widget.eventId);

        // Update the event document to add the userId to the list of participants
        await eventDocRef.update({'participants': FieldValue.arrayUnion([user.uid])});

        // Update the user document to save the eventId
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final userData = await userDocRef.get();
        final events = List<String>.from(userData.data()?['events'] ?? []);
        events.add(widget.eventId);
        await userDocRef.update({'events': events});

        setState(() {
          isJoined = true;
        });
      }
    } catch (error) {
      // ignore: avoid_print
      print('Error joining event: $error');
    }
  }
}