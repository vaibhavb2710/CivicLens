import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_list_view.dart';

class AllTasksDialog extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String status;
  final void Function(Map<String, dynamic> data) onComplete;
  final void Function(Map<String, dynamic> data) onStart;
  final void Function(Map<String, dynamic> data) onView;

  const AllTasksDialog({
    super.key,
    required this.stream,
    required this.status,
    required this.onComplete,
    required this.onStart,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    // Safely capitalize the status string
    String capitalizedStatus = status.isNotEmpty 
        ? '${status[0].toUpperCase()}${status.substring(1)}' 
        : 'Unknown';
    
    return AlertDialog(
      title: Text('All $capitalizedStatus Tasks'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: TaskListView(
          stream: stream,
          status: status,
          onComplete: onComplete,
          onStart: onStart,
          onView: onView,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
