import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_display.dart';
import 'add_event.dart';
import 'draft.dart';
import 'posted_event.dart';
import '../search.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    // Clear user session data
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userEmail');
    await prefs.remove('userRole'); // If you have user role stored

    // Navigate back to the login page
    // ignore: use_build_context_synchronously
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Explorer'),
        actions: <Widget>[
          // Add a search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to the search page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchPage(isAdmin: null),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Welcome Admin!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Add New Event'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEventPage(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Drafts'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DraftPage(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Event Posted'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PostedEvent(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: () {
                _logout(context);
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').where('status', isEqualTo: 'uploaded').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final List<QueryDocumentSnapshot> events = snapshot.data!.docs;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (BuildContext context, int index) {
              final event = events[index];
              final eventName = event['event_name'];
              final eventDescription = event['description'];
              return Card(
                elevation: 3, // Add elevation for a shadow effect
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Add margin for spacing between cards
                child: ListTile(
                  title: Text(eventName),
                  subtitle: Text(eventDescription.length <= 50 ? eventDescription : eventDescription.substring(0, 50) + '...'),
                  onTap: () {
                    // Navigate to event_display.dart and pass the event details
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminDisplayPage(eventId: event.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

