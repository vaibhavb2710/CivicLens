import 'package:flutter/material.dart';

class TaskItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final String reportId;
  final bool isActive;
  final VoidCallback onComplete;
  final VoidCallback onStart;
  final VoidCallback onView;
  final VoidCallback? onAssign;
  final VoidCallback? onDelete;

  const TaskItem({
    super.key,
    required this.data,
    required this.reportId,
    required this.isActive,
    required this.onComplete,
    required this.onStart,
    required this.onView,
    this.onAssign,
    this.onDelete,
  });

  // Helper method to get duration based on issue type
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
    String priority = data['priority']?.toString() ?? 'medium';
    Color priorityColor;
    switch (priority) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = const Color(0xFF8B7355);
        break;
      default:
        priorityColor = Colors.grey;
    }
    
    String title = data['title']?.toString() ?? 'No Title';
    String municipalStatus = data['municipalStatus']?.toString() ?? 'pending';
    bool isCompleted = municipalStatus == 'completed';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? Colors.brown.withValues(alpha: 0.1) : const Color(0xFFF5F3F0),
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: Colors.brown, width: 2) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF2D2D2D),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.brown,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'completed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          priority,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data['description']?.toString() ?? 'No description available',
                  style: const TextStyle(
                    color: Color(0xFF6B6B6B),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFF6B6B6B), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      data['userName']?.toString() ?? 'Unknown User',
                      style: const TextStyle(
                        color: Color(0xFF6B6B6B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.schedule, color: Color(0xFF6B6B6B), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _getCorrectDuration(),
                      style: const TextStyle(
                        color: Color(0xFF6B6B6B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (data['assignedWorkerId'] != null && !isActive && !isCompleted) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.assignment_ind,
                          color: Colors.blue,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Assigned to: ${data['assignedWorkerName'] ?? 'Unknown Worker'}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (data['assignedDepartment'] != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${data['assignedDepartment']})',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive)
                ElevatedButton(
                  onPressed: onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text(
                    'Complete',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                )
              else if (!isCompleted)
                ElevatedButton.icon(
                  icon: Icon(
                    data['assignedWorkerId'] != null ? Icons.play_arrow : Icons.assignment_ind,
                    size: 16,
                  ),
                  onPressed: () {
                    bool isAssigned = data['assignedWorkerId'] != null;
                    
                    if (isAssigned) {
                      onStart();
                    } else {
                      if (onAssign != null) {
                        onAssign!();
                      } else {
                        onStart();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: data['assignedWorkerId'] != null 
                        ? Colors.green
                        : const Color(0xFF8B7355),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data['assignedWorkerId'] != null ? 'Start' : 'Assign',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      if (data['assignedWorkerId'] != null) ...[
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_forward, size: 12),
                      ],
                    ],
                  ),
                ),
              if (!isCompleted)
                const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onView,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'View',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    if (isCompleted && data['completionImageUrl'] != null) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.photo_camera, size: 12),
                    ],
                  ],
                ),
              ),
              if (isCompleted && onDelete != null) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          )
        ],
      ),
    );
  }
}
