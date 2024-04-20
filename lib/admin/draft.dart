import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DraftPage extends StatefulWidget {
  const DraftPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DraftPageState createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drafts'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('events').where('status', isEqualTo: 'draft').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No drafts found.'),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              String documentId = document.id; // Store the document ID
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(data['event_name']),
                  subtitle: Text(data['description'].length <= 50 ? data['description'] : data['description'].substring(0, 50) + '...'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEventPage(eventData: data, documentId: documentId), // Pass the document ID
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}


class EditEventPage extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final String documentId;

  const EditEventPage({super.key, required this.eventData, required this.documentId});

  @override
  // ignore: library_private_types_in_public_api
  _EditEventPageState createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  late TextEditingController _eventNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  //final String _status = 'draft';
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _eventNameController = TextEditingController(text: widget.eventData['event_name']);
    _descriptionController = TextEditingController(text: widget.eventData['description']);
    _locationController = TextEditingController(text: widget.eventData['location']);
    _startDate = widget.eventData['start_datetime']?.toDate();
    _startTime = TimeOfDay.fromDateTime(widget.eventData['start_datetime'].toDate());
    _endDate = widget.eventData['end_datetime']?.toDate();
    _endTime = TimeOfDay.fromDateTime(widget.eventData['end_datetime'].toDate());

    // Retrieve image URL from eventData
    _imageUrl = widget.eventData['image_url'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _eventNameController,
              decoration: const InputDecoration(labelText: 'Event Name'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Date'),
                      InkWell(
                        onTap: () {
                          _selectDate(context, isStartDate: true);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(_startDate),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Time'),
                      InkWell(
                        onTap: () {
                          _selectTime(context, isStartTime: true);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Text(
                            '${_startTime.hour}:${_startTime.minute}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End Date'),
                      InkWell(
                        onTap: () {
                          _selectDate(context, isStartDate: false);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(_endDate),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End Time'),
                      InkWell(
                        onTap: () {
                          _selectTime(context, isStartTime: false);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Text(
                            '${_endTime.hour}:${_endTime.minute}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 20),
            // Display image or placeholder
            _buildImageWidget(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _saveEvent(true); // Save as Draft
                  },
                  child: const Text('Save as Draft'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _saveEvent(false); // Upload
                  },
                  child: const Text('Upload'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Function to build image widget or placeholder
  Widget _buildImageWidget() {
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      // If image URL is available, display the image with GestureDetector
      return GestureDetector(
        onTap: _changeImage, // Call _changeImage() function when tapped
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.network(
              _imageUrl!,
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            ),
            if (_imageUrl == null) // Show loading indicator only if image URL is null
              const CircularProgressIndicator(), // Circular loading indicator
          ],
        ),
      );
    } else {
      // If image URL is not available, display placeholder and allow user to add image
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Image',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _changeImage, // Call _changeImage() function when tapped
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_a_photo,
                size: 50,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      );
    }
  }

  void _changeImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      // Upload picked image to Firebase Storage
      String fileName = widget.eventData['event_name'] + '_' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      Reference ref = FirebaseStorage.instance.ref().child('event_images').child(fileName);
      UploadTask uploadTask = ref.putFile(File(pickedImage.path));
      
      // Get download URL from Firebase Storage
      uploadTask.whenComplete(() async {
        String imageUrl = await ref.getDownloadURL();
        
        // Update the image URL state variable
        setState(() {
          _imageUrl = imageUrl;
        });
      });
    }
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, {required bool isStartTime}) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          );
        },
    );

    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  void _saveEvent(bool isDraft) async {
    // Get the edited values from the text controllers
    String editedEventName = _eventNameController.text;
    String editedDescription = _descriptionController.text;
    String editedLocation = _locationController.text;

    // Update the event details in Firestore
    try {
      await FirebaseFirestore.instance.collection('events').doc(widget.documentId).update({
        'event_name': editedEventName,
        'description': editedDescription,
        'location': editedLocation,
        'start_date': _startDate,
        'end_date': _endDate,
        'status': isDraft ? 'draft' : 'uploaded', // Update status based on button pressed
      });

      // Show appropriate message based on the button pressed
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(isDraft ? 'Event Saved' : 'Event Uploaded'),
            content: Text(isDraft ? 'The event has been saved as a draft.' : 'The event has been uploaded successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      // Navigate back to the draft page if the event is saved as a draft
      if (isDraft) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      }
    } catch (error) {
      // Show an error message if updating fails
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to update event details: $error'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}
