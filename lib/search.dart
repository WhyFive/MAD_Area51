import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin/admin_display.dart';
import 'student/student_display.dart';

class SearchPage extends StatefulWidget {
  final bool? isAdmin;

  const SearchPage({super.key, required this.isAdmin});

  @override
  // ignore: library_private_types_in_public_api
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController _searchController;
  late List<QueryDocumentSnapshot> _searchResults;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchResults = [];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchEvents(String query) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('status', isEqualTo: 'uploaded')
        .get();

    final List<DocumentSnapshot<Map<String, dynamic>>> allEvents = snapshot.docs;
    
    // Filter events by query
    List<QueryDocumentSnapshot<Object?>> filteredEvents = allEvents.map((doc) {
      return doc as QueryDocumentSnapshot<Object?>;
    }).toList();

    // Sort events alphabetically by event name
    filteredEvents.sort((a, b) {
      final eventNameA = a['event_name'] as String;
      final eventNameB = b['event_name'] as String;
      return eventNameA.compareTo(eventNameB);
    });

    setState(() {
      _searchResults = filteredEvents;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search events...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                _searchEvents(_searchController.text);
              },
            ),
          ),
          onSubmitted: (value) {
            _searchEvents(value);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (BuildContext context, int index) {
          final event = _searchResults[index];
          final eventName = event['event_name'];
          final eventDescription = event['description'];
          return ListTile(
            title: Text(eventName),
            subtitle: Text(eventDescription),
            onTap: () {
              // Determine which display page to navigate based on user role
              if (widget.isAdmin != null && widget.isAdmin!) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminDisplayPage(eventId: event.id),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDisplayPage(eventId: event.id),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
