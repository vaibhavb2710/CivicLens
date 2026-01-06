import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../services/report_service.dart';
import 'dashboard_widgets/enhanced_dashboard_sidebar.dart';
import 'dashboard_widgets/dashboard_header.dart';
import 'dashboard_widgets/dashboard_stats_cards.dart';
import 'dashboard_widgets/dashboard_priority_tasks.dart';
import 'dashboard_widgets/dashboard_area_coverage_heatmap.dart';
import 'dashboard_widgets/dashboard_performance_overview.dart';
import 'dashboard_widgets/task_item.dart';
import 'task_management_screen.dart';
import 'task_assignment_screen.dart';

class MunicipalDashboard extends StatefulWidget {
  const MunicipalDashboard({super.key});

  @override
  State<MunicipalDashboard> createState() => _MunicipalDashboardState();
}

class _MunicipalDashboardState extends State<MunicipalDashboard> {
  final AuthService _authService = AuthService(); // Used for logout
  // final UserService _userService = UserService();
  final ReportService _reportService = ReportService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final Stream<QuerySnapshot> _pendingTasksStream;
  late final Stream<QuerySnapshot> _activeTasksStream;
  late final Stream<QuerySnapshot> _completedTasksStream;
  
  int _pendingCount = 0;
  int _activeCount = 0;
  int _completedCount = 0;
  int _newlyReportedCount = 0;
  int _selectedNavIndex = 0; // Add navigation state

  @override
  void initState() {
  super.initState();
  _pendingTasksStream = _reportService.getPendingTasks();
  _activeTasksStream = _reportService.getActiveTasks();
  _completedTasksStream = FirebaseFirestore.instance
      .collection('reports')
      .where('municipalStatus', isEqualTo: 'completed')
      .snapshots();
      
  // Listen to completed tasks stream to update count
  _completedTasksStream.listen((snapshot) {
    if (mounted) {
      setState(() {
        _completedCount = snapshot.docs.length;
      });
    }
  });

  // Enhanced debugging: Listen to pending tasks stream with detailed logging
  _pendingTasksStream.listen(
    (snapshot) {
      print('Municipal Dashboard: Pending tasks updated, count: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('Pending task: ${doc.id} - ${data['title']} - Status: ${data['municipalStatus']} - Created: ${data['createdAt']}');
      }
    },
    onError: (error) {
      print('Municipal Dashboard: Error in pending tasks stream: $error');
      _handleStreamError('Pending Tasks', error);
    },
  );

  // Listen to active tasks stream with error handling
  _activeTasksStream.listen(
    (snapshot) {
      print('Municipal Dashboard: Active tasks updated, count: ${snapshot.docs.length}');
    },
    onError: (error) {
      print('Municipal Dashboard: Error in active tasks stream: $error');
      _handleStreamError('Active Tasks', error);
    },
  );

  // Comprehensive initialization
  _initializeDashboard();
  }

  // Enhanced initialization method
  Future<void> _initializeDashboard() async {
    try {
      print('Municipal Dashboard: Starting comprehensive initialization...');
      
      // First, fix any missing municipalStatus fields in existing reports
      print('Municipal Dashboard: Checking for missing municipalStatus fields...');
      await _reportService.fixMissingMunicipalStatus();
      
      // Test database connection
      await _testDatabaseConnection();
      
      // Validate data sync
      await _validateDataSync();
      
      // Force refresh dashboard data
      await _reportService.forceRefreshDashboard();
      
      print('Municipal Dashboard: Initialization completed successfully');
    } catch (e) {
      print('Municipal Dashboard: Initialization failed: $e');
      _showErrorSnackBar('Dashboard initialization failed: $e');
    }
  }

  // Enhanced data sync validation
  Future<void> _validateDataSync() async {
    try {
      print('Municipal Dashboard: Running data sync validation...');
      Map<String, dynamic> syncStatus = await _reportService.validateDataSync();
      
      print('Municipal Dashboard: Sync validation results: $syncStatus');
      
      if (!syncStatus['isValid']) {
        List<String> errors = List<String>.from(syncStatus['errors']);
        String errorMsg = 'Data sync issues detected: ${errors.join(', ')}';
        _showErrorSnackBar(errorMsg);
      }
      
      // Show sync status to user if there are warnings
      List<String> warnings = List<String>.from(syncStatus['warnings']);
      if (warnings.isNotEmpty) {
        print('Municipal Dashboard: Sync warnings: $warnings');
      }
      
    } catch (e) {
      print('Municipal Dashboard: Sync validation failed: $e');
    }
  }

  // Handle stream errors
  void _handleStreamError(String streamName, dynamic error) {
    print('Municipal Dashboard: $streamName stream error: $error');
    if (mounted) {
      _showErrorSnackBar('$streamName data sync error. Please refresh.');
    }
  }

  // Show error snack bar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              _initializeDashboard();
            },
          ),
        ),
      );
    }
  }

  // Build error widget for data migration issues
  Widget _buildMigrationErrorWidget() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Data Migration Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Some reports need to be updated to work with the new dashboard. This is a one-time operation.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Migrating data... Please wait.')),
                    );
                    await _reportService.fixMissingMunicipalStatus();
                    await _initializeDashboard();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data migration completed!')),
                    );
                  } catch (e) {
                    _showErrorSnackBar('Migration failed: $e');
                  }
                },
                child: const Text('Fix Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build generic error widget
  Widget _buildGenericErrorWidget(String context, VoidCallback onRetry) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error Loading $context',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unable to load data. Please check your connection and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Debug method to test database connection
  Future<void> _testDatabaseConnection() async {
    try {
      print('Municipal Dashboard: Testing database connection...');
      
      // Test direct Firestore access
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .limit(10)
          .get();
      
      print('Municipal Dashboard: Found ${snapshot.docs.length} total reports');
      
      // Check specifically for pending reports
      QuerySnapshot pendingSnapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('municipalStatus', isEqualTo: 'pending')
          .get();
      
      print('Municipal Dashboard: Found ${pendingSnapshot.docs.length} pending reports');
      
      for (var doc in pendingSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('Pending report: ${doc.id} - ${data['title']} - Created: ${data['createdAt']}');
      }
      
    } catch (e) {
      print('Municipal Dashboard: Database connection test failed: $e');
    }
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, {String? badge}) {
    return Material(
      child: InkWell(
        onTap: () {
          // Handle navigation tap
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blue : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[50],
        appBar: MediaQuery.of(context).size.width < 768
            ? AppBar(
                backgroundColor: Colors.white,
                elevation: 1,
                leading: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black87),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                title: const Text(
                  'Municipal Dashboard',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                ),
              )
            : null,
        drawer: MediaQuery.of(context).size.width < 768
            ? ClipRRect(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                child: SizedBox(
                  width: 300,
                  child: EnhancedDashboardSidebar(
                    onLogout: () async {
                      await _authService.signOut();
                      if (mounted) {
                        Navigator.of(context).pushReplacementNamed('/role-selection');
                      }
                    },
                    onNavigationChanged: (index) {
                      setState(() {
                        _selectedNavIndex = index;
                      });
                    },
                    selectedIndex: _selectedNavIndex,
                  ),
                ),
              )
            : null,
        body: Row(
          children: [
            if (MediaQuery.of(context).size.width >= 768)
              RepaintBoundary(
                child: SizedBox(
                  width: 250,
                  child: EnhancedDashboardSidebar(
                    onLogout: () async {
                      await _authService.signOut();
                      if (mounted) {
                        Navigator.of(context).pushReplacementNamed('/role-selection');
                      }
                    },
                    onNavigationChanged: (index) {
                      setState(() {
                        _selectedNavIndex = index;
                      });
                    },
                    selectedIndex: _selectedNavIndex,
                  ),
                ),
              ),
            Expanded(
              child: RepaintBoundary(
                child: _buildMainContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return _buildLiveCityMapContent();
      case 2:
        return const TaskManagementScreen();
      case 3:
        return const TaskAssignmentScreen();
      case 4:
        return _buildPerformanceContent();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: _pendingTasksStream,
      builder: (context, pendingSnapshot) {
        // Debug logging for pending stream
        print('Municipal Dashboard: Pending stream - hasData: ${pendingSnapshot.hasData}, hasError: ${pendingSnapshot.hasError}');
        if (pendingSnapshot.hasError) {
          print('Municipal Dashboard: Pending stream error: ${pendingSnapshot.error}');
          
          // Check if error is related to missing municipalStatus field
          String errorStr = pendingSnapshot.error.toString();
          if (errorStr.contains('municipalStatus') || errorStr.contains('field') || errorStr.contains('Null check operator')) {
            return _buildMigrationErrorWidget();
          }
          
          return _buildGenericErrorWidget('Pending tasks', () => _initializeDashboard());
        }
        if (pendingSnapshot.hasData) {
          print('Municipal Dashboard: Pending stream has ${pendingSnapshot.data!.docs.length} documents');
        }
        
        return StreamBuilder<QuerySnapshot>(
          stream: _activeTasksStream,
          builder: (context, activeSnapshot) {
            // Debug logging for active stream
            print('Municipal Dashboard: Active stream - hasData: ${activeSnapshot.hasData}, hasError: ${activeSnapshot.hasError}');
            if (activeSnapshot.hasError) {
              print('Municipal Dashboard: Active stream error: ${activeSnapshot.error}');
              
              // Check if error is related to missing municipalStatus field
              String errorStr = activeSnapshot.error.toString();
              if (errorStr.contains('municipalStatus') || errorStr.contains('field') || errorStr.contains('Null check operator')) {
                return _buildMigrationErrorWidget();
              }
              
              return _buildGenericErrorWidget('Active tasks', () => _initializeDashboard());
            }
            
            // Ensure counts are never null
            int pendingCount = pendingSnapshot.hasData && pendingSnapshot.data != null 
                ? pendingSnapshot.data!.docs.length 
                : 0;
            int activeCount = activeSnapshot.hasData && activeSnapshot.data != null 
                ? activeSnapshot.data!.docs.length 
                : 0;
            
            List<QueryDocumentSnapshot> activeTasks = activeSnapshot.hasData && activeSnapshot.data != null 
                ? activeSnapshot.data!.docs 
                : <QueryDocumentSnapshot>[];
            List<QueryDocumentSnapshot> pendingTasks = pendingSnapshot.hasData && pendingSnapshot.data != null 
                ? pendingSnapshot.data!.docs 
                : <QueryDocumentSnapshot>[];
                
            // Calculate newly reported tasks
            int newlyReportedCount = pendingTasks.where((task) {
              Map<String, dynamic> data = task.data() as Map<String, dynamic>;
              return _reportService.isNewlyReported(data);
            }).length;
            
            print('Municipal Dashboard: Current counts - Pending: $pendingCount, Active: $activeCount');
            print('Municipal Dashboard: Found $newlyReportedCount newly reported tasks');
            
            // Update instance variables for sidebar with null safety
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _pendingCount = pendingCount;
                  _activeCount = activeCount;
                  _newlyReportedCount = newlyReportedCount;
                });
              }
            });
            
            // Sort pending tasks by priority with null safety
            pendingTasks.sort((a, b) {
              Map<String, dynamic> dataA = a.data() as Map<String, dynamic>? ?? {};
              Map<String, dynamic> dataB = b.data() as Map<String, dynamic>? ?? {};
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
              return getPriorityValue(priorityB).compareTo(getPriorityValue(priorityA));
            });
            
            int urgentCount = pendingTasks.where((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
              return data['priority']?.toString() == 'high';
            }).length;
            
            return Material(
              child: Container(
                constraints: const BoxConstraints.expand(),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DashboardHeader(
                        officerName: 'Officer',
                        pendingCount: pendingCount,
                        activeCount: activeCount,
                        onViewTasks: () {}, // Implement if needed
                      ),
                      const SizedBox(height: 24),
                      DashboardStatsCards(
                        activeCount: activeCount,
                        completedCount: _completedCount, // Already initialized as non-null
                        pendingCount: pendingCount,
                        newlyReportedCount: newlyReportedCount,
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 768) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: DashboardPriorityTasks(
                                    activeTasks: activeTasks,
                                    pendingTasks: pendingTasks,
                                    buildTaskItem: (doc) => _buildTaskItemWidget(doc),
                                    urgentCount: urgentCount,
                                    onViewAllTasks: () {}, // Implement if needed
                                  ),
                                ),
                                const SizedBox(width: 24),
                                const Expanded(
                                  child: DashboardAreaCoverageHeatmap(),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                DashboardPriorityTasks(
                                  activeTasks: activeTasks,
                                  pendingTasks: pendingTasks,
                                  buildTaskItem: (doc) => _buildTaskItemWidget(doc),
                                  urgentCount: urgentCount,
                                  onViewAllTasks: () {}, // Implement if needed
                                ),
                                const SizedBox(height: 24),
                                const DashboardAreaCoverageHeatmap(),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      const DashboardPerformanceOverview(),
                    ],
                  ),
                ),
              ),
            );
          },
        );
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
              SnackBar(
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
              SnackBar(
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
        setState(() {
          _selectedNavIndex = 3; // Task Assignment screen is at index 3
        });
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
                _buildDetailRow('Issue Type', data['issueType']?.toString() ?? 'N/A'),
                _buildDetailRow('Description', data['description']?.toString() ?? 'N/A'),
                _buildDetailRow('Priority', data['priority']?.toString() ?? 'N/A'),
                _buildDetailRow('Status', data['municipalStatus']?.toString() ?? 'N/A'),
                _buildDetailRow('Reported By', data['userName']?.toString() ?? 'N/A'),
                _buildDetailRow('Report ID', doc.id),
                if (data['createdAt'] != null)
                  _buildDetailRow('Created', _formatTimestamp(data['createdAt'])),
                if (data['startedAt'] != null)
                  _buildDetailRow('Started', _formatTimestamp(data['startedAt'])),
                if (data['completedAt'] != null)
                  _buildDetailRow('Completed', _formatTimestamp(data['completedAt'])),
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
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to task assignment screen for this specific task
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TaskAssignmentScreen(taskId: doc.id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                child: const Text('Assign', style: TextStyle(color: Colors.white)),
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

  Widget _buildLiveCityMapContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Live City Map',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Interactive city map with real-time data coming soon...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Performance Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Detailed performance metrics and analytics coming soon...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
