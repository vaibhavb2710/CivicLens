import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/report_service.dart';

class TaskAssignmentScreen extends StatefulWidget {
  final String? taskId; // Optional task ID to pre-select
  
  const TaskAssignmentScreen({super.key, this.taskId});

  @override
  State<TaskAssignmentScreen> createState() => _TaskAssignmentScreenState();
}

class _TaskAssignmentScreenState extends State<TaskAssignmentScreen> {
  final ReportService _reportService = ReportService();
  
  String? selectedDepartment;
  String? selectedWorkerId;
  String? selectedTaskId;
  bool isLoading = false;
  
  final List<String> departments = [
    'Electrical',
    'Roads',
    'Solid Waste Management'
  ];
  
  // Department to issue type mapping
  final Map<String, List<String>> departmentIssueMapping = {
    'Electrical': ['streetlights', 'street lights', 'lighting'],
    'Roads': ['potholes', 'pothole', 'road', 'roads'],
    'Solid Waste Management': ['trash', 'waste', 'garbage', 'sanitation', 'cleaning'],
  };
  
  // Get relevant issue types for selected department
  List<String> _getRelevantIssueTypes(String department) {
    return departmentIssueMapping[department] ?? [];
  }
  
  // Check if an issue is relevant to the selected department
  bool _isIssueRelevantToDepartment(String issueType, String department) {
    List<String> relevantTypes = _getRelevantIssueTypes(department);
    String lowerIssueType = issueType.toLowerCase();
    
    return relevantTypes.any((type) => lowerIssueType.contains(type.toLowerCase()));
  }
  
  // Get human-readable description of department-specific issues
  String _getDepartmentSpecificIssues(String department) {
    switch (department) {
      case 'Electrical':
        return 'streetlight and electrical';
      case 'Roads':
        return 'pothole and road';
      case 'Solid Waste Management':
        return 'trash and waste management';
      default:
        return 'relevant';
    }
  }
  
  // Get the appropriate department for an issue type
  String _getDepartmentForIssue(String issueType) {
    String lowerIssueType = issueType.toLowerCase();
    
    for (String department in departmentIssueMapping.keys) {
      List<String> relevantTypes = departmentIssueMapping[department]!;
      if (relevantTypes.any((type) => lowerIssueType.contains(type.toLowerCase()))) {
        return department;
      }
    }
    
    return 'General';
  }
  
  // Get icon for department
  IconData _getDepartmentIcon(String department) {
    switch (department) {
      case 'Electrical':
        return Icons.electrical_services;
      case 'Roads':
        return Icons.construction;
      case 'Solid Waste Management':
        return Icons.delete_outline;
      default:
        return Icons.business;
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
          'Assigning Tasks',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B7355).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.group_work,
                          color: Color(0xFF8B7355),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Assign Tasks to Workers',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D2D2D),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select a department, choose a worker, and assign pending tasks',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Department Selection
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Step 1: Select Department',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tasks will be filtered to show only relevant issues for the selected department',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDepartment,
                    hint: const Text('Choose a department'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF8B7355)),
                      ),
                      prefixIcon: const Icon(Icons.business),
                    ),
                    items: departments.map((String department) {
                      return DropdownMenuItem<String>(
                        value: department,
                        child: Text(department),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedDepartment = value;
                        selectedWorkerId = null; // Reset worker selection
                        selectedTaskId = null; // Reset task selection when department changes
                      });
                    },
                  ),
                  
                  // Show department-specific issue types
                  if (selectedDepartment != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B7355).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF8B7355).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getDepartmentIcon(selectedDepartment!),
                            color: const Color(0xFF8B7355),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$selectedDepartment department handles: ${_getDepartmentSpecificIssues(selectedDepartment!)} issues',
                              style: const TextStyle(
                                color: Color(0xFF8B7355),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Worker Selection
            if (selectedDepartment != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step 2: Select Worker',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildWorkerSelection(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Task Selection
            if (selectedWorkerId != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step 3: Select Task to Assign',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTaskSelection(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Assignment Button
            if (selectedTaskId != null && selectedWorkerId != null) ...[
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _assignTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B7355),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Assign Task to Worker',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerSelection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'worker')
          .where('department', isEqualTo: selectedDepartment)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No workers found in $selectedDepartment department',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          );
        }

        List<QueryDocumentSnapshot> workers = snapshot.data!.docs;
        
        return Column(
          children: workers.map((worker) {
            Map<String, dynamic> workerData = worker.data() as Map<String, dynamic>;
            String workerId = worker.id;
            String workerName = workerData['username'] ?? 'Unknown Worker';
            String workerEmail = workerData['email'] ?? '';
            bool isSelected = selectedWorkerId == workerId;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedWorkerId = workerId;
                    selectedTaskId = null; // Reset task selection
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF8B7355).withOpacity(0.1) 
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF8B7355) 
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF8B7355),
                        radius: 20,
                        child: Text(
                          workerName.isNotEmpty ? workerName[0].toUpperCase() : 'W',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workerName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                    ? const Color(0xFF8B7355) 
                                    : Colors.black87,
                              ),
                            ),
                            if (workerEmail.isNotEmpty)
                              Text(
                                workerEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            Text(
                              selectedDepartment!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF8B7355),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTaskSelection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _reportService.getPendingTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Task Assignment: Error in pending tasks stream: ${snapshot.error}');
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Error loading tasks: ${snapshot.error}',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Force rebuild
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No pending tasks available for assignment',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          );
        }

        List<QueryDocumentSnapshot> allTasks = snapshot.data!.docs;
        print('Task Assignment: Loaded ${allTasks.length} total pending tasks');
        
        // Filter tasks that are not already assigned
        List<QueryDocumentSnapshot> unassignedTasks = allTasks.where((task) {
          Map<String, dynamic> taskData = task.data() as Map<String, dynamic>;
          return taskData['assignedWorkerId'] == null;
        }).toList();
        print('Task Assignment: Found ${unassignedTasks.length} unassigned tasks');
        
        // Filter tasks by department if department is selected
        List<QueryDocumentSnapshot> filteredTasks = unassignedTasks;
        if (selectedDepartment != null) {
          filteredTasks = unassignedTasks.where((task) {
            Map<String, dynamic> taskData = task.data() as Map<String, dynamic>;
            String issueType = taskData['issueType']?.toString() ?? '';
            return _isIssueRelevantToDepartment(issueType, selectedDepartment!);
          }).toList();
          print('Task Assignment: Filtered to ${filteredTasks.length} tasks for $selectedDepartment department');
        }
        
        if (filteredTasks.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDepartment != null
                        ? 'No ${_getDepartmentSpecificIssues(selectedDepartment!)} issues available for assignment to $selectedDepartment department'
                        : 'All pending tasks have been assigned',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          );
        }

        // Sort tasks by priority and creation time
        filteredTasks.sort((a, b) {
          Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
          Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
          
          // First prioritize newly reported tasks
          bool isNewA = _reportService.isNewlyReported(dataA);
          bool isNewB = _reportService.isNewlyReported(dataB);
          if (isNewA && !isNewB) return -1;
          if (!isNewA && isNewB) return 1;
          
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
          
          // Finally sort by creation time (newest first)
          Timestamp? timeA = dataA['createdAt'] as Timestamp?;
          Timestamp? timeB = dataB['createdAt'] as Timestamp?;
          
          if (timeA != null && timeB != null) {
            return timeB.compareTo(timeA);
          }
          
          return 0;
        });

        return Column(
          children: [
            // Department filter info
            if (selectedDepartment != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B7355).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF8B7355).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: const Color(0xFF8B7355), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Showing ${_getDepartmentSpecificIssues(selectedDepartment!)} issues for $selectedDepartment department',
                        style: const TextStyle(
                          color: Color(0xFF8B7355),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '${filteredTasks.length} task${filteredTasks.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Color(0xFF8B7355),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Task list
            ...filteredTasks.map((task) {
              Map<String, dynamic> taskData = task.data() as Map<String, dynamic>;
              String taskId = task.id;
              String issueType = taskData['issueType'] ?? 'Unknown Issue';
              String description = taskData['description'] ?? '';
              String priority = taskData['priority'] ?? 'medium';
              String reportedBy = taskData['userName'] ?? 'Unknown User';
              bool isSelected = selectedTaskId == taskId;
              bool isNewlyReported = _reportService.isNewlyReported(taskData);
              
              Color priorityColor = _getPriorityColor(priority);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedTaskId = taskId;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF8B7355).withOpacity(0.1) 
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFF8B7355) 
                            : (isNewlyReported ? Colors.green : Colors.grey[300]!),
                        width: isSelected ? 2 : (isNewlyReported ? 2 : 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isNewlyReported) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fiber_new, color: Colors.white, size: 12),
                                    SizedBox(width: 2),
                                    Text(
                                      'NEW',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
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
                                color: const Color(0xFF8B7355).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getDepartmentForIssue(issueType).toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF8B7355),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF8B7355),
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          issueType,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                                ? const Color(0xFF8B7355) 
                                : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Reported by: $reportedBy',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                            if (isNewlyReported) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Just reported',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
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

  Future<void> _assignTask() async {
    if (selectedTaskId == null || selectedWorkerId == null || selectedDepartment == null) {
      _showSnackBar('Please select a task and worker first', Colors.red);
      return;
    }

    // Show confirmation dialog
    bool? confirmed = await _showConfirmationDialog();
    if (confirmed != true) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Get worker information
      DocumentSnapshot workerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(selectedWorkerId!)
          .get();
      
      if (!workerDoc.exists) {
        throw 'Worker not found';
      }
      
      Map<String, dynamic> workerData = workerDoc.data() as Map<String, dynamic>;
      String workerName = workerData['username'] ?? 'Unknown Worker';
      
      // Get task information for confirmation
      DocumentSnapshot taskDoc = await FirebaseFirestore.instance
          .collection('reports')
          .doc(selectedTaskId!)
          .get();
          
      if (!taskDoc.exists) {
        throw 'Task not found';
      }
      
      Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;
      String taskTitle = taskData['issueType'] ?? 'Unknown Task';
      
      // Use the new assignTaskToWorker method for proper workflow
      await _reportService.assignTaskToWorker(
        reportId: selectedTaskId!,
        workerId: selectedWorkerId!,
        workerName: workerName,
        department: selectedDepartment!,
        estimatedDuration: _getEstimatedDuration(taskData['issueType'] ?? ''),
        notes: 'Assigned via Municipal Dashboard',
      );

      _showSnackBar('Task "$taskTitle" assigned successfully to $workerName', Colors.green);
      
      // Reset selections
      setState(() {
        selectedTaskId = null;
        selectedWorkerId = null;
        selectedDepartment = null;
      });
      
    } catch (e) {
      _showSnackBar('Error assigning task: $e', Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  // Get estimated duration based on issue type
  String _getEstimatedDuration(String issueType) {
    switch (issueType.toLowerCase()) {
      case 'potholes':
        return '4 days';
      case 'streetlights':
        return '5 days';
      case 'trash':
        return '2 days';
      case 'parks':
        return '3 days';
      case 'sanitation':
        return '3 days';
      case 'traffic signs':
        return '3 days';
      case 'water issues':
        return '3 days';
      default:
        return '3 days';
    }
  }

  Future<bool?> _showConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Task Assignment'),
          content: const Text('Are you sure you want to assign this task to the selected worker?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B7355),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
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
}