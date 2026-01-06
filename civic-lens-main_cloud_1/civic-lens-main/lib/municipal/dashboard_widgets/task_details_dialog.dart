import 'package:flutter/material.dart';

class TaskDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onComplete;
  final VoidCallback? onStart;
  final bool isActive;
  final bool isPending;

  const TaskDetailsDialog({
    super.key,
    required this.data,
    this.onComplete,
    this.onStart,
    this.isActive = false,
    this.isPending = false,
  });

  // Helper method to get correct duration based on issue type
  String _getCorrectDuration() {
    String? storedDuration = data['estimatedDuration']?.toString();
    String? issueType = data['issueType']?.toString().toLowerCase();
    
    // If it's already in days format, return it
    if (storedDuration != null && storedDuration.contains('days')) {
      return storedDuration;
    }
    
    // Convert based on issue type
    if (issueType != null) {
      switch (issueType) {
        case 'potholes':
          return '4 days';
        case 'streetlights':
          return '5 days';
        case 'trash':
        case 'trashcan':
          return '2 days';
        case 'parks':
        case 'sanitation':
          return '3 days';
        case 'traffic signs':
          return '2 days';
        case 'water issues':
          return '5 days';
        default:
          return '3 days';
      }
    }
    
    return storedDuration ?? '3 days';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(data['title'] ?? 'Task Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['description'] ?? ''),
            const SizedBox(height: 8),
            Text('Priority: ${data['priority'] ?? 'medium'}'),
            const SizedBox(height: 8),
            Text('Reported by: ${data['userName'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Estimated Duration: ${_getCorrectDuration()}'),
          ],
        ),
      ),
      actions: [
        if (isActive && onComplete != null)
          ElevatedButton(
            onPressed: onComplete,
            child: const Text('Complete'),
          ),
        if (isPending && onStart != null)
          ElevatedButton(
            onPressed: onStart,
            child: const Text('Start'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
