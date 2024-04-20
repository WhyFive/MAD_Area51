import 'package:flutter/material.dart';

class CustomCalendarController { // Ensure that the class name matches
  late DateTime _selectedDate;
  late ValueNotifier<DateTime> _selectedDateNotifier;

  CustomCalendarController({DateTime? initialDate}) {
    _selectedDate = initialDate ?? DateTime.now();
    _selectedDateNotifier = ValueNotifier<DateTime>(_selectedDate);
  }

  DateTime get selectedDate => _selectedDate;

  ValueNotifier<DateTime> get selectedDateNotifier => _selectedDateNotifier;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _selectedDateNotifier.value = _selectedDate;
  }

  void dispose() {
    _selectedDateNotifier.dispose();
  }
}
