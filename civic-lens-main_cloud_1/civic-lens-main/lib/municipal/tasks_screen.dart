import 'package:flutter/material.dart';

class Task {
  final String title;
  final String desc;
  final String userName;
  final Duration duration;
  final String status; // 'active', 'pending', etc.
  final String priority; // 'high', 'medium', etc.
  final String imageUrl; // Can be empty or actual URL
  final String municipalStatus;

  Task({
    required this.title,
    required this.desc,
    required this.userName,
    required this.duration,
    required this.status,
    required this.priority,
    required this.imageUrl,
    required this.municipalStatus,
  });
}

class TasksScreen extends StatelessWidget {
  final List<Task> tasks;
  final void Function(Task) onStart;

  // Pass your list of tasks and start handler
  const TasksScreen({
    super.key,
    required this.tasks,
    required this.onStart,
  });

  void _showTaskDetails(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Chip(label: Text(task.priority.toUpperCase())),
                    const SizedBox(width: 8),
                    Chip(label: Text(task.municipalStatus)),
                    const Spacer(),
                    Text(_getCorrectDuration(task),
                        style: const TextStyle(color: Color(0xFF8B7355))),
                  ],
                ),
                const Divider(height: 28),
                if (task.imageUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        task.imageUrl,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64),
                        loadingBuilder: (ctx, widget, progress) =>
                        progress == null ? widget : const CircularProgressIndicator(),
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Description: ${task.desc}",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text("Assigned to: ", style: const TextStyle(color: Colors.black54)),
                    Text(task.userName,
                      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text("Status: ", style: TextStyle(color: Colors.black54)),
                    Text(task.status,
                        style: TextStyle(
                            color: (task.status == 'active')
                                ? Colors.blue
                                : (task.status == 'pending')
                                ? Colors.orange
                                : Colors.green,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF8B7355),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Close'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: tasks.length,
      padding: const EdgeInsets.all(16),
      separatorBuilder: (ctx, idx) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) {
        final task = tasks[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE8E6E1)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(task.desc, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              if (task.status == 'pending' || task.status == 'high')
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF8B7355),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  onPressed: () => onStart(task),
                  child: const Text('Start'),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                onPressed: () => _showTaskDetails(context, task),
                child: const Text('View'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to get correct duration based on task title/type
  String _getCorrectDuration(Task task) {
    String title = task.title.toLowerCase();
    
    if (title.contains('pothole')) {
      return '4 days';
    } else if (title.contains('streetlight') || title.contains('street light')) {
      return '5 days';
    } else if (title.contains('trash') || title.contains('garbage')) {
      return '2 days';
    } else {
      return '3 days';
    }
  }
}
