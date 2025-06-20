import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrainUtils {
  /// Get color based on train status
  static Color getStatusColor(String status) {
    final s = status.toUpperCase();
    if (s.contains('ON TIME')) return Colors.green;
    if (s.contains('LATE') || s.contains('DELAY')) return Colors.orange;
    if (s.contains('EARLY')) return Colors.lightBlue;
    if (s.contains('CANCELLED')) return Colors.red;
    if (s.contains('BOARD') || s.contains('DEPART')) return Colors.blue;
    if (s.contains('ARRIVED')) return Colors.teal;
    return Colors.grey;
  }

  /// Format time in h:mm a format
  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }
}
