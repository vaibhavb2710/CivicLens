import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_item.dart';

class TaskListView extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String status;
  final void Function(Map<String, dynamic> data) onComplete;
  final void Function(Map<String, dynamic> data) onStart;
  final void Function(Map<String, dynamic> data) onView;

  const TaskListView({
    super.key,
    required this.stream,
    required this.status,
    required this.onComplete,
    required this.onStart,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF8B7355)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'pending' ? Icons.pending_actions :
                  status == 'active' ? Icons.play_circle_fill : Icons.check_circle,
                  size: 64,
                  color: const Color(0xFF6B6B6B),
                ),
                const SizedBox(height: 16),
                Text(
                  'No $status tasks',
                  style: const TextStyle(
                    color: Color(0xFF6B6B6B),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (status == 'pending')
                  const Text(
                    'New citizen reports will appear here',
                    style: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          );
        }
        List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
        if (status == 'pending') {
          docs.sort((a, b) {
            Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
            Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
            String priorityA = dataA['priority'] ?? 'medium';
            String priorityB = dataB['priority'] ?? 'medium';
            int getPriorityValue(String priority) {
              switch (priority) {
                case 'high': return 3;
                case 'medium': return 2;
                case 'low': return 1;
                default: return 2;
              }
            }
            return getPriorityValue(priorityB).compareTo(getPriorityValue(priorityA));
          });
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> data = docs[index].data() as Map<String, dynamic>;
            String reportId = docs[index].id;
            bool isActive = status == 'active';
            return TaskItem(
              data: data,
              reportId: reportId,
              isActive: isActive,
              onComplete: () => onComplete(data),
              onStart: () => onStart(data),
              onView: () => onView(data),
              onDelete: null, // No delete functionality in this view
            );
          },
        );
      },
    );
  }
}
