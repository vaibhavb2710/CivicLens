import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' show min;
import '../services/report_service.dart';
import '../services/user_service.dart';
import '../services/pothole_detection_service.dart';

class WorkerAssignedTasksScreen extends StatefulWidget {
  const WorkerAssignedTasksScreen({super.key});

  @override
  State<WorkerAssignedTasksScreen> createState() => _WorkerAssignedTasksScreenState();
}

class _WorkerAssignedTasksScreenState extends State<WorkerAssignedTasksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ReportService _reportService = ReportService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? currentWorkerId;
  String? currentWorkerDepartment;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed from 4 to 3 tabs
    _getCurrentWorkerInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentWorkerInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      currentWorkerId = user.uid;
      
      // Get worker's department
      Map<String, dynamic>? userData = await _userService.getUserProfile(user.uid);
      if (userData != null) {
        setState(() {
          currentWorkerDepartment = userData['department'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentWorkerId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assigned Tasks',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            if (currentWorkerDepartment != null)
              Text(
                '$currentWorkerDepartment Department',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF8B7355),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF8B7355),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active Tasks'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList('assigned', 'pending'), // Pending tasks (assigned but not started)
          _buildTaskList('active', 'active'), // Active tasks (started)
          _buildTaskList('completed', 'completed'), // Completed tasks
        ],
      ),
    );
  }

  Widget _buildTaskList(String statusFilter, String displayStatus) {
    return StreamBuilder<QuerySnapshot>(
      stream: _reportService.getWorkerTasksByStatus(currentWorkerId!, statusFilter),
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
                  _getIconForStatus(statusFilter),
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No $displayStatus tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptyMessageForStatus(statusFilter),
                  textAlign: TextAlign.center,
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
        
        // Sort tasks by priority and creation time
        tasks.sort((a, b) {
          Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
          Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
          
          // First sort by priority
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
          
          // Then sort by assignment time (newest first)
          Timestamp? timeA = dataA['assignedAt'] as Timestamp?;
          Timestamp? timeB = dataB['assignedAt'] as Timestamp?;
          
          if (timeA != null && timeB != null) {
            return timeB.compareTo(timeA);
          }
          
          return 0;
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return _buildTaskCard(tasks[index], statusFilter);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(QueryDocumentSnapshot doc, String status) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String reportId = doc.id;
    String issueType = data['issueType'] ?? 'Unknown Issue';
    String title = data['title'] ?? issueType;
    String description = data['description'] ?? '';
    String priority = data['priority'] ?? 'medium';
    String reportedBy = data['userName'] ?? 'Unknown User';
    
    Timestamp? assignedAt = data['assignedAt'] as Timestamp?;
    Timestamp? acceptedAt = data['acceptedAt'] as Timestamp?;
    Timestamp? startedAt = data['startedAt'] as Timestamp?;
    Timestamp? completedAt = data['completedAt'] as Timestamp?;
    
    Color priorityColor = _getPriorityColor(priority);
    Color statusColor = _getStatusColor(status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with priority and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showTaskDetailsDialog(doc),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Task Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 4),
              
              // Issue Type
              Text(
                issueType,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8B7355),
                ),
              ),
              
              // Description
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Task Info
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Reported by: $reportedBy',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Timestamps
              if (assignedAt != null)
                Row(
                  children: [
                    Icon(Icons.assignment, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Assigned: ${_formatTimestamp(assignedAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              
              if (acceptedAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Accepted: ${_formatTimestamp(acceptedAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
              
              if (startedAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.play_circle, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Started: ${_formatTimestamp(startedAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
              
              if (completedAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.done_all, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Completed: ${_formatTimestamp(completedAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Action Buttons
              _buildActionButtons(reportId, status, data),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(String reportId, String status, Map<String, dynamic> data) {
    List<Widget> buttons = [];
    
    switch (status) {
      case 'assigned':
        // Task is pending - worker can start it directly
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _startTask(reportId),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Start'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B7355),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        );
        break;
        
      case 'active':
        // Task is active - worker can complete it with photo evidence
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _completeTask(reportId),
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('Complete with Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        );
        break;
        
      case 'completed':
        // Task is completed - show status
        buttons.add(
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Task Completed',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        break;
    }
    
    if (buttons.isEmpty) {
      return const SizedBox();
    }
    
    return Row(
      children: buttons,
    );
  }

  Future<void> _startTask(String reportId) async {
    try {
      _showSnackBar('Starting task...', Colors.blue);
      await _reportService.startAssignedTask(reportId);
      
      // Add a short delay to allow Firestore to update
      await Future.delayed(const Duration(milliseconds: 300));
      
      _showSnackBar('Task started successfully! Task moved to Active Tasks tab.', Colors.green);
      
      // Automatically switch to Active Tasks tab
      if (mounted) {
        setState(() {
          _tabController.animateTo(1); // Switch to Active Tasks tab (index 1)
        });
      }
    } catch (e) {
      _showSnackBar('Error starting task: $e', Colors.red);
      print('Error in _startTask: $e');
    }
  }

  Future<void> _completeTask(String reportId) async {
    try {
      // Show loading indicator first
      _showSnackBar('Opening camera for completion evidence...', Colors.blue);
      
      // Open camera with fast capture and optimized processing 
      Map<String, dynamic> verificationData = 
          await PotholeDetectionService.captureAndVerifyTaskCompletion(
            useBackgroundProcessing: true,  // Use background processing for better UX
            imageQuality: 85               // Good quality/compression balance
          );
      
      if (!verificationData['success']) {
        _showSnackBar('Failed to capture completion evidence: ${verificationData['error']}', Colors.orange);
        return;
      }

      // Show preview and confirm before submitting - this happens quickly now
      bool shouldComplete = await _showCompletionConfirmationDialog(verificationData);
      
      if (!shouldComplete) {
        _showSnackBar('Task completion cancelled', Colors.grey);
        return;
      }
      
      // Show processing status with detailed dialog
      _showProcessingDialog(reportId, verificationData);
      
      // Complete the task with evidence (optimized process)
      Map<String, dynamic> result = 
          await _reportService.completeAssignedTask(reportId, completionData: verificationData);
      
      // Hide processing dialog
      Navigator.pop(context);
      
      if (result['success']) {
        _showSnackBar('Task completed successfully with evidence!', Colors.green);
        
        // Automatically switch to Completed Tasks tab
        if (mounted) {
          setState(() {
            _tabController.animateTo(2); // Switch to Completed Tasks tab (index 2)
          });
        }
      } else {
        _showSnackBar('Error completing task: ${result['error']}', Colors.red);
      }
      
    } catch (e) {
      _showSnackBar('Error completing task: $e', Colors.red);
      print('Error in task completion process: $e');
    }
  }
  
  // Enhanced dialog with captured image and quick confirmation with improved offline support
  Future<bool> _showCompletionConfirmationDialog(Map<String, dynamic> verificationData) async {
    // Check if we're in offline mode (server unavailable)
    bool isOfflineMode = verificationData['offlineMode'] == true || 
                        verificationData['serverAvailable'] == false;
    
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Text('Confirm Task Completion'),
              if (isOfflineMode) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Working in offline mode - ML analysis unavailable',
                  child: Icon(Icons.offline_bolt, size: 16, color: Colors.orange),
                )
              ],
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show offline mode warning if needed
                if (isOfflineMode)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.orange.shade800, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Offline Mode: Server unavailable. Task can still be completed using local verification.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          // Use different color for offline mode
                          color: isOfflineMode ? Colors.orange : Colors.green,
                          width: isOfflineMode ? 2.0 : 1.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: verificationData['imageFile'] != null
                            ? Image.file(
                                verificationData['imageFile'],
                                fit: BoxFit.cover,
                              )
                            : verificationData['webImageBytes'] != null
                                ? Image.memory(
                                    verificationData['webImageBytes'],
                                    fit: BoxFit.cover,
                                  )
                                : const Center(
                                    child: Text('No image available'),
                                  ),
                      ),
                    ),
                    // Show image size indicator with offline badge if needed
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isOfflineMode)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.offline_bolt, color: Colors.orange, size: 10),
                            ),
                          Text(
                            verificationData['imageSize'] != null
                                ? '${verificationData['imageSize']} KB'
                                : 'Image ready',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on, 
                      color: verificationData['location'] != null ? Colors.green : Colors.orange, 
                      size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        verificationData['location'] != null
                            ? 'Location captured: ${verificationData['location'].latitude.toStringAsFixed(6)}, ${verificationData['location'].longitude.toStringAsFixed(6)}'
                            : 'No location captured',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isOfflineMode ? Icons.check_circle_outline : Icons.check_circle, 
                      color: isOfflineMode ? Colors.orange : Colors.green, 
                      size: 16
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOfflineMode
                            ? 'Local verification: Image evidence captured'
                            : 'AI analysis: Verification complete',
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: isOfflineMode ? FontWeight.normal : FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isOfflineMode
                      ? 'Your task can be completed with offline verification. The system will sync when online.'
                      : 'Do you want to complete this task with the captured evidence?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOfflineMode ? Colors.orange.shade800 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOfflineMode ? Colors.orange : Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: Icon(isOfflineMode ? Icons.cloud_off : Icons.check_circle),
              label: Text(isOfflineMode 
                  ? 'Complete Task (Offline)'
                  : 'Complete Task'),
            ),
          ],
        );
      },
    ) ?? false; // Default to false if dialog is dismissed
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
                _buildDetailRow('Issue Type', data['issueType']?.toString() ?? 'N/A'),
                _buildDetailRow('Description', data['description']?.toString() ?? 'N/A'),
                _buildDetailRow('Priority', data['priority']?.toString() ?? 'N/A'),
                _buildDetailRow('Status', data['municipalStatus']?.toString() ?? 'N/A'),
                _buildDetailRow('Reported By', data['userName']?.toString() ?? 'N/A'),
                _buildDetailRow('Assigned Worker', data['assignedWorkerName']?.toString() ?? 'N/A'),
                _buildDetailRow('Department', data['assignedDepartment']?.toString() ?? 'N/A'),
                _buildDetailRow('Report ID', doc.id),
                if (data['assignedAt'] != null)
                  _buildDetailRow('Assigned', _formatTimestamp(data['assignedAt'])),
                if (data['acceptedAt'] != null)
                  _buildDetailRow('Accepted', _formatTimestamp(data['acceptedAt'])),
                if (data['startedAt'] != null)
                  _buildDetailRow('Started', _formatTimestamp(data['startedAt'])),
                if (data['completedAt'] != null)
                  _buildDetailRow('Completed', _formatTimestamp(data['completedAt'])),
                if (data['estimatedDuration'] != null)
                  _buildDetailRow('Est. Duration', _getCorrectDuration(data)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
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

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  // Enhanced processing dialog with animated progress indicator and step tracking
  void _showProcessingDialog(String reportId, Map<String, dynamic> verificationData) {
    // Check if we're in offline mode (server unavailable)
    bool isOfflineMode = verificationData['offlineMode'] == true || 
                        verificationData['serverAvailable'] == false;
    
    // Use a StatefulBuilder to update dialog content during processing
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Track processing progress - customize steps based on offline mode
            final steps = isOfflineMode 
              ? [
                  {'label': 'Saving image evidence locally', 'done': false},
                  {'label': 'Basic verification (offline mode)', 'done': false},
                  {'label': 'Updating task records', 'done': false},
                ]
              : [
                  {'label': 'Processing image evidence', 'done': false},
                  {'label': 'Verifying completion details', 'done': false},
                  {'label': 'Updating task records', 'done': false},
                ];
            
            // Simulate progress updates with slightly faster timing in offline mode
            // This is just for visual feedback during background processing
            Future.delayed(Duration(milliseconds: isOfflineMode ? 300 : 500), () {
              if (mounted) {
                setState(() => steps[0]['done'] = true);
                
                Future.delayed(Duration(milliseconds: isOfflineMode ? 500 : 800), () {
                  if (mounted) {
                    setState(() => steps[1]['done'] = true);
                    
                    Future.delayed(Duration(milliseconds: isOfflineMode ? 400 : 700), () {
                      if (mounted) {
                        setState(() => steps[2]['done'] = true);
                      }
                    });
                  }
                });
              }
            });
            
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Offline mode indicator if needed
                    if (isOfflineMode)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.offline_bolt, color: Colors.orange.shade800, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'OFFLINE MODE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Animated progress indicator
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: isOfflineMode ? Colors.orange : Theme.of(context).primaryColor,
                            strokeWidth: 6.0,
                          ),
                          if (isOfflineMode)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.orange, width: 2),
                                ),
                                child: Icon(Icons.wifi_off, size: 14, color: Colors.orange.shade800),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isOfflineMode 
                          ? 'Processing Task Completion (Offline)'
                          : 'Processing Task Completion',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isOfflineMode) ...[
                      const SizedBox(height: 8),
                      Text(
                        'ML server unavailable - using basic verification',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    
                    // Dynamic step indicators
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: steps.map((step) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                step['done'] == true ? Icons.check_circle : Icons.pending,
                                color: step['done'] == true 
                                    ? (isOfflineMode ? Colors.orange : Colors.green) 
                                    : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                step['label'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: step['done'] == true 
                                      ? (isOfflineMode ? Colors.orange.shade800 : Colors.green)
                                      : Colors.black87,
                                  fontWeight: step['done'] == true ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Image preview (small thumbnail)
                    if (verificationData['imageFile'] != null || verificationData['webImageBytes'] != null)
                      Container(
                        height: 60,
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isOfflineMode ? Colors.orange.shade300 : Colors.grey.shade300,
                            width: isOfflineMode ? 2.0 : 1.0,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: verificationData['imageFile'] != null
                                  ? Image.file(
                                      verificationData['imageFile'],
                                      fit: BoxFit.cover,
                                    )
                                  : verificationData['webImageBytes'] != null
                                      ? Image.memory(
                                          verificationData['webImageBytes'],
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                            ),
                            if (isOfflineMode)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.offline_bolt, 
                                    size: 12, 
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    Text(
                      'Report ID: ${reportId.substring(0, min(8, reportId.length))}...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    // Additional info for offline mode
                    if (isOfflineMode) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Text(
                          'Tasks completed offline will sync when connection is restored',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          }
        );
      },
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

  Color _getPriorityColor(String priority) {
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'in-progress':
        return Colors.orange;
      case 'completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Icons.assignment; // Pending tasks
      case 'active':
        return Icons.work_outline; // Active tasks
      case 'completed':
        return Icons.done_all; // Completed tasks
      default:
        return Icons.task;
    }
  }

  String _getEmptyMessageForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return 'No pending tasks assigned to you\nNew assignments will appear here';
      case 'active':
        return 'No active tasks\nStart a pending task to see it here';
      case 'completed':
        return 'No completed tasks yet\nCompleted work will appear here';
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