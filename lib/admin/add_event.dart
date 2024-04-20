import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  File? _image;
  bool _isDraft = false;

  @override
  void dispose() {
    _eventNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Event Name'),
                Column(
                  children: [
                    TextField(
                      controller: _eventNameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter event name',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description'),
                Column(
                  children: [
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Enter description',
                      ),
                    ),
                  ],
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
                      const Text('Start Date'),
                      InkWell(
                        onTap: () {
                          _selectDate(context, isStartDate: true);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Text(_startDate != null
                              ? DateFormat('yyyy-MM-dd').format(_startDate!)
                              : 'Select date'),
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
                          child: Text(_startTime != null
                              ? '${_startTime!.hour}:${_startTime!.minute}'
                              : 'Select time'),
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
                          child: Text(_endDate != null
                              ? DateFormat('yyyy-MM-dd').format(_endDate!)
                              : 'Select date'),
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
                          child: Text(_endTime != null
                              ? '${_endTime!.hour}:${_endTime!.minute}'
                              : 'Select time'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Location'),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    hintText: 'Enter location',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
            onTap: (){_getImage();},
            child: _image != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Image'),
                      Image.file(
                        _image!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ],
                  )
                : Container(
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isDraft = true;
                    });
                    _saveEvent();
                  },
                  child: const Text('Save as Draft'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isDraft = false;
                    });
                    _saveEvent();
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

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Event Saved'),
          content: const Text('Your event has been saved successfully.'),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _clearInputFields(); // Clear input fields
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _clearInputFields() {
    setState(() {
      _eventNameController.clear();
      _descriptionController.clear();
      _startDate = null;
      _endDate = null;
      _startTime = null;
      _endTime = null;
      _locationController.clear();
      _image = null;
    });
  }

  void _saveEvent() async {
    if (_eventNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _startDate == null ||
        _startTime == null ||
        _endDate == null ||
        _endTime == null ||
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in all fields'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Convert start and end dates to timestamps
    DateTime startDateTime = DateTime(_startDate!.year, _startDate!.month, _startDate!.day, _startTime!.hour, _startTime!.minute);
    DateTime endDateTime = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, _endTime!.hour, _endTime!.minute);

    // Upload image to Firebase Storage
    String imageUrl = '';
    if (_image != null) {
      String eventName = _eventNameController.text.replaceAll(' ', '_'); // Replace spaces with underscores
      Reference storageReference = FirebaseStorage.instance.ref().child('event_images/$eventName-${DateTime.now()}.png');
      UploadTask uploadTask = storageReference.putFile(_image!);

      try {
        await uploadTask;
        imageUrl = await storageReference.getDownloadURL();
      } catch (e) {
        // ignore: avoid_print
        print('Error uploading image: $e');
      }
    }

    // Create event object
    Map<String, dynamic> event = {
      'event_name': _eventNameController.text,
      'description': _descriptionController.text,
      'start_datetime': Timestamp.fromDate(startDateTime), // Save start date and time as a single timestamp
      'end_datetime': Timestamp.fromDate(endDateTime), // Save end date and time as a single timestamp
      'location': _locationController.text,
      'image_url': imageUrl, // Store image URL in Firestore
      'status': _isDraft ? 'draft' : 'uploaded',
    };

    // Save event to Firestore
    await FirebaseFirestore.instance.collection('events').add(event);
    // ignore: avoid_print
    print('Event saved as ${_isDraft ? 'draft' : 'uploaded'}');

    _showConfirmationDialog();
  }
}