import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/report_service.dart';
import '../services/task_sync_service.dart';
import 'dashboard_widgets/task_item.dart';
import 'task_assignment_screen.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ReportService _reportService = ReportService();

  final TaskSyncService _syncService = TaskSyncService();
  late StreamSubscription<TaskSyncEvent> _syncSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Listen for task sync events to update UI on status changes
    _syncSubscription = _syncService.syncStream.listen(_handleTaskSync);
  }

  @override
  void dispose() {
    _syncSubscription.cancel();
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTaskSync(TaskSyncEvent event) {
    print('Task sync event received: ${event.toString()}');
    
    // Switch to the appropriate tab based on the new status
    if (mounted) {
      switch (event.newStatus) {
        case 'active':
          setState(() {
            // Switch to Active Tasks tab
            _tabController.animateTo(1);
          });
          break;
        case 'completed':
          setState(() {
            // Switch to Completed Tasks tab
            _tabController.animateTo(2);
          });
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Task Management',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF8B7355),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF8B7355),
          tabs: const [
            Tab(text: 'Pending Tasks'),
            Tab(text: 'Active Tasks'),
            Tab(text: 'Completed Tasks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(_reportService.getPendingTasks(), 'pending'),
          _buildTaskList(_reportService.getActiveTasks(), 'active'),
          _buildTaskList(_reportService.getCompletedTasks(), 'completed'),
        ],
      ),
    );
  }

  Widget _buildTaskList(Stream<QuerySnapshot> stream, String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForStatus(status),
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No $status tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptyMessageForStatus(status),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        List<QueryDocumentSnapshot> tasks = snapshot.data!.docs;
        
        // Sort tasks by:
        // 1. Status (assigned vs. pending)
        // 2. Priority
        // 3. Creation time
        tasks.sort((a, b) {
          Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
          Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
          
          // First sort by task status (assigned tasks first)
          bool isAssignedA = dataA['assignedWorkerId'] != null && dataA['municipalStatus'] == 'assigned';
          bool isAssignedB = dataB['assignedWorkerId'] != null && dataB['municipalStatus'] == 'assigned';
          
          // If both tasks are either assigned or unassigned, continue with other sorting criteria
          // If one is assigned and the other is not, prioritize assigned task
          if (isAssignedA != isAssignedB) {
            return isAssignedA ? -1 : 1;
          }
          
          // Then sort by priority
          String priorityA = dataA['priority']?.toString() ?? 'medium';
          String priorityB = dataB['priority']?.toString() ?? 'medium';
          
          int getPriorityValue(String priority) {
            switch (priority) {
              case 'high': return 3;
              case 'medium': return 2;
              case 'low': return 1;
              default: return 2;
            }
          }
          
          int priorityComparison = getPriorityValue(priorityB).compareTo(getPriorityValue(priorityA));
          if (priorityComparison != 0) return priorityComparison;
          
          // Then sort by creation time (newest first)
          Timestamp? timeA = dataA['createdAt'] as Timestamp?;
          Timestamp? timeB = dataB['createdAt'] as Timestamp?;
          
          if (timeA != null && timeB != null) {
            return timeB.compareTo(timeA);
          }
          
          return 0;
        });

        // For pending tab, we want to group tasks by assignment status
        if (status == 'pending') {
          // Separate tasks into assigned and unassigned
          List<QueryDocumentSnapshot> assignedTasks = [];
          List<QueryDocumentSnapshot> unassignedTasks = [];
          
          for (var task in tasks) {
            Map<String, dynamic> data = task.data() as Map<String, dynamic>;
            if (data['assignedWorkerId'] != null && data['municipalStatus'] == 'assigned') {
              assignedTasks.add(task);
            } else {
              unassignedTasks.add(task);
            }
          }
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Assigned tasks section
              if (assignedTasks.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_ind, color: Colors.blue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Assigned Tasks (${assignedTasks.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      Text(
                        'Waiting to start',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...assignedTasks.map((task) => _buildTaskItemWidget(task)),
                const SizedBox(height: 16),
              ],
              
              // Unassigned tasks section
              if (unassignedTasks.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B7355).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.new_releases, color: Color(0xFF8B7355), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Unassigned Tasks (${unassignedTasks.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8B7355),
                          ),
                        ),
                      ),
                      Text(
                        'Needs assignment',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...unassignedTasks.map((task) => _buildTaskItemWidget(task)),
              ],
            ],
          );
        } else {
          // For other tabs, use regular list builder
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return _buildTaskItemWidget(tasks[index]);
            },
          );
        }
      },
    );
  }

  Widget _buildTaskItemWidget(QueryDocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String reportId = doc.id;
    bool isActive = data['municipalStatus'] == 'active';
    
    return TaskItem(
      data: data,
      reportId: reportId,
      isActive: isActive,
      onComplete: () async {
        try {
          await _reportService.completeTask(reportId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Task completed successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error completing task: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      onStart: () async {
        try {
          await _reportService.startTask(reportId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Task started successfully'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error starting task: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      onAssign: () {
        // Navigate to task assignment screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TaskAssignmentScreen(),
          ),
        );
      },
      onView: () {
        _showTaskDetailsDialog(doc);
      },
      onDelete: data['municipalStatus'] == 'completed' ? () async {
        // Show confirmation dialog before deleting
        bool? confirmDelete = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Task'),
              content: const Text('Are you sure you want to delete this completed task? This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );

        // If user confirmed deletion
        if (confirmDelete == true) {
          try {
            await _reportService.deleteCompletedTask(reportId);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting task: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } : null, // Only provide delete callback for completed tasks
    );
  }

  void _showTaskDetailsDialog(QueryDocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(data['title']?.toString() ?? 'Task Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display completion evidence if available
                if (data['completionImageUrl'] != null) ...[
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            data['completionImageUrl'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Text('Failed to load image: $error', textAlign: TextAlign.center),
                                  ],
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                              color: Colors.black.withOpacity(0.7),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified, color: Colors.green, size: 16),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      'Task completion evidence',
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  if (data['completionAnalysis'] != null &&
                                      data['completionAnalysis']['aiProcessed'] == true)
                                    const Text(
                                      'AI Verified',
                                      style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildDetailRow('Issue Type', data['issueType']?.toString() ?? 'N/A'),
                _buildDetailRow('Description', data['description']?.toString() ?? 'N/A'),
                _buildDetailRow('Priority', data['priority']?.toString() ?? 'N/A'),
                _buildDetailRow('Status', data['municipalStatus']?.toString() ?? 'N/A'),
                _buildDetailRow('Reported By', data['userName']?.toString() ?? 'N/A'),
                _buildDetailRow('User Email', data['userEmail']?.toString() ?? 'N/A'),
                _buildDetailRow('Report ID', doc.id),
                if (data['createdAt'] != null)
                  _buildDetailRow('Created', _formatTimestamp(data['createdAt'])),
                if (data['startedAt'] != null)
                  _buildDetailRow('Started', _formatTimestamp(data['startedAt'])),
                if (data['completedAt'] != null)
                  _buildDetailRow('Completed', _formatTimestamp(data['completedAt'])),
                if (data['estimatedDuration'] != null)
                  _buildDetailRow('Est. Duration', _getCorrectDuration(data)),
                // Display completion location if available
                if (data['completionLocation'] != null) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Completion Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildDetailRow('Latitude', data['completionLocation']['latitude'].toString()),
                  _buildDetailRow('Longitude', data['completionLocation']['longitude'].toString()),
                  _buildDetailRow('Accuracy', '${data['completionLocation']['accuracy']} meters'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (data['municipalStatus'] == 'pending')
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await _reportService.startTask(doc.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task started successfully'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error starting task: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                child: const Text('Start Task', style: TextStyle(color: Colors.white)),
              ),
            if (data['municipalStatus'] == 'active')
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await _reportService.completeTask(doc.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task completed successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error completing task: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Complete Task', style: TextStyle(color: Colors.white)),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      if (timestamp is Timestamp) {
        DateTime dateTime = timestamp.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
      return timestamp.toString();
    } catch (e) {
      return 'Invalid date';
    }
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'active':
        return Icons.play_circle_fill;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.assignment;
    }
  }

  String _getEmptyMessageForStatus(String status) {
    switch (status) {
      case 'pending':
        return 'New reports will appear here';
      case 'active':
        return 'Started tasks will appear here';
      case 'completed':
        return 'Completed tasks will appear here';
      default:
        return 'No tasks available';
    }
  }

  // Helper method to get correct duration based on issue type
  String _getCorrectDuration(Map<String, dynamic> data) {
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
}