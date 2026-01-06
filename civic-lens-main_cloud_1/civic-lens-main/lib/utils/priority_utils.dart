import 'package:flutter/material.dart';

// Utility functions for managing priorities in the application

/// Converts a string priority to its corresponding value for sorting
int getPriorityValue(String priority) {
  switch (priority.toLowerCase()) {
    case 'high':
      return 3;
    case 'medium':
      return 2;
    case 'low':
      return 1;
    default:
      return 2; // Default to medium priority
  }
}

/// Get the color associated with a priority level
Color getPriorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'high':
      return Colors.red;
    case 'medium':
      return Colors.orange;
    case 'low':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

/// Get the icon associated with a priority level
IconData getPriorityIcon(String priority) {
  switch (priority.toLowerCase()) {
    case 'high':
      return Icons.priority_high;
    case 'medium':
      return Icons.remove_circle_outline;
    case 'low':
      return Icons.arrow_downward;
    default:
      return Icons.help_outline;
  }
}

/// Convert from numeric priority (1,2,3) to string representation
String numericToStringPriority(int priority) {
  switch (priority) {
    case 3:
      return 'high';
    case 2:
      return 'medium';
    case 1:
      return 'low';
    default:
      return 'medium';
  }
}