import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPriorityTasks extends StatelessWidget {
  final List<QueryDocumentSnapshot> activeTasks;
  final List<QueryDocumentSnapshot> pendingTasks;
  final Function(QueryDocumentSnapshot) buildTaskItem;
  final int urgentCount;
  final VoidCallback onViewAllTasks;

  const DashboardPriorityTasks({
    super.key,
    required this.activeTasks,
    required this.pendingTasks,
    required this.buildTaskItem,
    required this.urgentCount,
    required this.onViewAllTasks,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure we don't take a negative number of pending tasks
    int remainingSlots = (3 - activeTasks.length).clamp(0, 3);
    List<QueryDocumentSnapshot> displayTasks = [
      ...activeTasks,
      ...pendingTasks.take(remainingSlots)
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E6E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Today\'s Priority Tasks',
                  style: TextStyle(
                    color: Color(0xFF2D2D2D),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                if (activeTasks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.brown,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${activeTasks.length} Active',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (urgentCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$urgentCount Urgent',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (displayTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment,
                      size: 48,
                      color: Color(0xFF6B6B6B),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No tasks available',
                      style: TextStyle(
                        color: Color(0xFF6B6B6B),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'New reports will appear here',
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...displayTasks.take(3).map((doc) => buildTaskItem(doc)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onViewAllTasks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F3F0),
                  foregroundColor: const Color(0xFF2D2D2D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'View All Tasks',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
