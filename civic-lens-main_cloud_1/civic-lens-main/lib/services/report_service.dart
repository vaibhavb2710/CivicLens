import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'notification_service.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // ENHANCED: Submit a report with AI detection support (including trash detection)
  Future<String> submitReport({
    required String issueType,
    required String title,
    required String description,
    required String urgencyLevel,
    String? imageUrl,
    bool hasVoiceNote = false,
    Map<String, dynamic>? locationData, // Enhanced location data support
    Map<String, dynamic>?
    aiDetectionData, // AI detection data support (including trash)
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      print('Submitting report for user: ${user.uid}'); // Debug log

      // Get user details
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      Map<String, dynamic> userData = {};

      if (userDoc.exists && userDoc.data() != null) {
        userData = userDoc.data() as Map<String, dynamic>;
      }

      // Create report document with proper structure
      Map<String, dynamic> reportData = {
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'userName': userData['username'] ?? 'Unknown User',
        'issueType': issueType,
        'title': title,
        'description': description,
        'urgencyLevel': urgencyLevel,
        'imageUrl': imageUrl,
        'hasVoiceNote': hasVoiceNote,
        'status': 'Submitted',
        'municipalStatus': 'pending', // For municipal task tracking
        'assignedOfficer': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'startedAt': null,
        'completedAt': null,

        // Municipal task fields
        'priority': _mapUrgencyToPriority(urgencyLevel),
        'estimatedDuration': _getEstimatedDuration(issueType),
        'assignedArea': 'Districts 5A-5C',
      };

      // ENHANCED: Process location data with GPS coordinates
      if (locationData != null) {
        // Add GPS coordinates to main document
        if (locationData.containsKey('latitude') &&
            locationData.containsKey('longitude')) {
          reportData['latitude'] = locationData['latitude'];
          reportData['longitude'] = locationData['longitude'];
        }

        if (locationData.containsKey('hasGPS')) {
          reportData['hasGPS'] = locationData['hasGPS'];
        }

        // Enhanced location structure
        reportData['location'] = {
          'address':
              locationData['location'] ??
              'Location will be captured automatically',
          'coordinates': locationData['hasGPS'] == true
              ? {
                  'latitude': locationData['latitude'],
                  'longitude': locationData['longitude'],
                }
              : null,
        };
      } else {
        // Default location structure (your original logic)
        reportData['location'] = {
          'address': 'Location will be captured automatically',
          'coordinates': null,
        };
        reportData['hasGPS'] = false;
      }

      // NEW: Enhanced AI detection data processing (including trash detection)
      if (aiDetectionData != null) {
        // Store comprehensive AI detection data
        Map<String, dynamic> aiData = {
          'hasAI': true,
          'type': aiDetectionData['type'] ?? 'unknown',
          'confidence': aiDetectionData['confidence'] ?? 0.0,
          'detectionClass': aiDetectionData['detectionClass'] ?? 'unknown',
        };

        // Process specific detection types
        if (aiDetectionData['type'] == 'pothole') {
          aiData['isPothole'] = aiDetectionData['isPothole'] ?? false;
          print(
            'AI Pothole Detection - isPothole: ${aiData['isPothole']}, confidence: ${aiData['confidence']}',
          );

          // Auto-adjust priority based on pothole detection confidence
          if (aiDetectionData['isPothole'] == true &&
              aiDetectionData['confidence'] != null) {
            double confidence = aiDetectionData['confidence'].toDouble();
            if (confidence > 0.8) {
              reportData['priority'] = 'high';
              reportData['urgencyLevel'] = 'High';
            } else if (confidence > 0.5) {
              reportData['priority'] = 'medium';
            }
          }
        } else if (aiDetectionData['type'] == 'streetlight') {
          aiData['isStreetlight'] = aiDetectionData['isStreetlight'] ?? false;
          print(
            'AI Streetlight Detection - isStreetlight: ${aiData['isStreetlight']}, confidence: ${aiData['confidence']}',
          );

          // Auto-adjust priority based on streetlight detection confidence
          if (aiDetectionData['isStreetlight'] == true &&
              aiDetectionData['confidence'] != null) {
            double confidence = aiDetectionData['confidence'].toDouble();
            if (confidence > 0.8) {
              reportData['priority'] = 'high';
              reportData['urgencyLevel'] = 'High';
            } else if (confidence > 0.5) {
              reportData['priority'] = 'medium';
            }
          }
        } else if (aiDetectionData['type'] == 'trash') {
          // NEW: Add trash detection handling
          aiData['isTrash'] = aiDetectionData['isTrash'] ?? false;
          print(
            'AI Trash Detection - isTrash: ${aiData['isTrash']}, confidence: ${aiData['confidence']}',
          );

          // Auto-adjust priority based on trash detection confidence
          if (aiDetectionData['isTrash'] == true &&
              aiDetectionData['confidence'] != null) {
            double confidence = aiDetectionData['confidence'].toDouble();
            if (confidence > 0.8) {
              reportData['priority'] = 'high';
              reportData['urgencyLevel'] = 'High';
              // High confidence trash issues get faster resolution time
              reportData['estimatedDuration'] = '1 day';
            } else if (confidence > 0.5) {
              reportData['priority'] = 'medium';
              reportData['estimatedDuration'] = '2 days';
            }
          }
        }

        // Store the complete AI detection data
        reportData['aiDetection'] = aiData;

        // Add AI verification flag for municipal officers
        reportData['isAIVerified'] = true;
      } else {
        // Default no AI detection (your original logic)
        reportData['aiDetection'] = {'hasAI': false, 'type': 'none'};
        reportData['isAIVerified'] = false;
      }

      print('Report data: $reportData'); // Debug log

      DocumentReference docRef = await _firestore
          .collection('reports')
          .add(reportData);

      print('Report created with ID: ${docRef.id}'); // Debug log

      return docRef.id;
    } catch (e) {
      print('Error submitting report: $e'); // Debug log
      throw 'Error submitting report: $e';
    }
  }

  // Helper method to map urgency to priority
  String _mapUrgencyToPriority(String urgencyLevel) {
    switch (urgencyLevel.toLowerCase()) {
      case 'high':
        return 'high';
      case 'medium':
        return 'medium';
      case 'low':
        return 'low';
      default:
        return 'medium';
    }
  }

  // UPDATED: Helper method to get estimated duration based on issue type (including trash)
  String _getEstimatedDuration(String issueType) {
    switch (issueType.toLowerCase()) {
      case 'potholes':
        return '4 days';
      case 'streetlights':
        return '5 days';
      case 'trash':
        return '2 days'; // Trash bins typically have faster resolution
      case 'trashcan':
        return '2 days';
      case 'parks':
        return '3 days';
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

  // FIXED: Get user's reports without orderBy (temporarily)
  Stream<QuerySnapshot> getUserReports() {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found'); // Debug log
        return const Stream.empty();
      }

      print('Getting reports for user: ${user.uid}'); // Debug log

      // Simplified query without orderBy to avoid index requirement
      return _firestore
          .collection('reports')
          .where('userId', isEqualTo: user.uid)
          .snapshots();
    } catch (e) {
      print('Error getting user reports: $e'); // Debug log
      return const Stream.empty();
    }
  }

  // FIXED: Get all reports without orderBy
  Stream<QuerySnapshot> getAllReports() {
    try {
      print('Getting all reports'); // Debug log
      return _firestore.collection('reports').snapshots();
    } catch (e) {
      print('Error getting all reports: $e'); // Debug log
      return const Stream.empty();
    }
  }

  // Get pending tasks including assigned but not started tasks
  Stream<QuerySnapshot> getPendingTasks() {
    try {
      print('Getting pending tasks (including assigned)'); // Debug log
      return _firestore
          .collection('reports')
          .where(
            'municipalStatus',
            whereIn: ['pending', 'assigned'],
          ) // Include assigned tasks in pending tab
          .snapshots()
          .handleError((error) {
            print('Error in pending tasks stream: $error');
            throw 'Failed to get pending tasks: $error';
          });
    } catch (e) {
      print('Error getting pending tasks: $e'); // Debug log
      return const Stream.empty();
    }
  }

  // Get new/unassigned tasks (pending tasks that haven't been assigned to workers)
  Stream<QuerySnapshot> getUnassignedTasks() {
    try {
      print('Getting unassigned tasks'); // Debug log
      return _firestore
          .collection('reports')
          .where('municipalStatus', isEqualTo: 'pending')
          .where('assignedWorkerId', isNull: true)
          .snapshots()
          .handleError((error) {
            print('Error in unassigned tasks stream: $error');
            throw 'Failed to get unassigned tasks: $error';
          });
    } catch (e) {
      print('Error getting unassigned tasks: $e'); // Debug log
      return const Stream.empty();
    }
  }

  // Get newly reported tasks (within last 24 hours)
  Stream<QuerySnapshot> getNewlyReportedTasks() {
    try {
      DateTime yesterday = DateTime.now().subtract(const Duration(hours: 24));
      Timestamp yesterdayTimestamp = Timestamp.fromDate(yesterday);

      print('Getting newly reported tasks since: $yesterday'); // Debug log
      return _firestore
          .collection('reports')
          .where('municipalStatus', isEqualTo: 'pending')
          .where('createdAt', isGreaterThan: yesterdayTimestamp)
          .snapshots()
          .handleError((error) {
            print('Error in newly reported tasks stream: $error');
            throw 'Failed to get newly reported tasks: $error';
          });
    } catch (e) {
      print('Error getting newly reported tasks: $e'); // Debug log
      return const Stream.empty();
    }
  }

  // Get active tasks
  Stream<QuerySnapshot> getActiveTasks() {
    try {
      print('Getting active tasks'); // Debug log
      return _firestore
          .collection('reports')
          .where('municipalStatus', isEqualTo: 'active')
          .snapshots()
          .handleError((error) {
            print('Error in active tasks stream: $error');
            throw 'Failed to get active tasks: $error';
          });
    } catch (e) {
      print('Error getting active tasks: $e'); // Debug log
      return const Stream.empty();
    }
  }

  // FIXED: Get completed tasks without orderBy
  Stream<QuerySnapshot> getCompletedTasks() {
    try {
      return _firestore
          .collection('reports')
          .where('municipalStatus', isEqualTo: 'completed')
          .snapshots();
    } catch (e) {
      print('Error getting completed tasks: $e'); // Debug log
      return const Stream.empty();
    }
  }

  // Get assigned tasks for a specific worker
  Stream<QuerySnapshot> getAssignedTasks(String workerId) {
    try {
      print('Getting assigned tasks for worker: $workerId'); // Debug log
      return _firestore
          .collection('reports')
          .where('assignedWorkerId', isEqualTo: workerId)
          .snapshots();
    } catch (e) {
      print('Error getting assigned tasks: $e'); // Debug log
      return const Stream.empty();
    }
  }

  // Get assigned tasks by department
  Stream<QuerySnapshot> getAssignedTasksByDepartment(String department) {
    try {
      print('Getting assigned tasks for department: $department'); // Debug log
      return _firestore
          .collection('reports')
          .where('assignedDepartment', isEqualTo: department)
          .where('municipalStatus', isEqualTo: 'assigned')
          .snapshots();
    } catch (e) {
      print('Error getting assigned tasks by department: $e'); // Debug log
      return const Stream.empty();
    }
  }

  // Get assigned tasks with specific status for a worker
  Stream<QuerySnapshot> getWorkerTasksByStatus(String workerId, String status) {
    try {
      print('Getting $status tasks for worker: $workerId'); // Debug log
      return _firestore
          .collection('reports')
          .where('assignedWorkerId', isEqualTo: workerId)
          .where('municipalStatus', isEqualTo: status)
          .snapshots();
    } catch (e) {
      print('Error getting worker tasks by status: $e'); // Debug log
      return const Stream.empty();
    }
  }

  // Worker accepts an assigned task (moves from assigned to accepted)
  Future<void> acceptAssignedTask(String reportId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      print('Worker accepting task: $reportId'); // Debug log

      // First update the document without the taskHistory
      await _firestore.collection('reports').doc(reportId).update({
        'municipalStatus': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'Accepted by Worker',
      });

      // Get the current timestamp manually
      final timestamp = Timestamp.now();

      // Then update the taskHistory with the manually created timestamp
      await _firestore.collection('reports').doc(reportId).update({
        'taskHistory': FieldValue.arrayUnion([
          {'action': 'accepted', 'timestamp': timestamp, 'workerId': user.uid},
        ]),
      });

      print('Task accepted successfully'); // Debug log

      // Trigger real-time sync
      await _triggerRealTimeSync(reportId, 'accepted');
    } catch (e) {
      print('Error accepting task: $e'); // Debug log
      throw 'Error accepting task: $e';
    }
  }

  // Worker starts an assigned task (moves from accepted/assigned to active)
  Future<void> startAssignedTask(String reportId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      print('Worker starting assigned task: $reportId'); // Debug log

      // Get report data for notification
      DocumentSnapshot reportDoc = await _firestore
          .collection('reports')
          .doc(reportId)
          .get();
      if (!reportDoc.exists) throw 'Report not found';

      Map<String, dynamic> reportData =
          reportDoc.data() as Map<String, dynamic>;
      String originalUserId = reportData['userId'] ?? '';
      String taskTitle = reportData['title'] ?? 'Your reported issue';

      // Get worker's name for notification
      DocumentSnapshot workerDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      String workerName = 'A worker';
      if (workerDoc.exists && workerDoc.data() != null) {
        Map<String, dynamic> workerData =
            workerDoc.data() as Map<String, dynamic>;
        workerName = workerData['username'] ?? 'A worker';
      }

      // First update the document without the taskHistory
      await _firestore.collection('reports').doc(reportId).update({
        'municipalStatus':
            'active', // Changed from 'in-progress' to 'active' for consistency
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'In Progress',
      });

      // Get the current timestamp manually
      final timestamp = Timestamp.now();

      // Then update the taskHistory with the manually created timestamp
      await _firestore.collection('reports').doc(reportId).update({
        'taskHistory': FieldValue.arrayUnion([
          {'action': 'started', 'timestamp': timestamp, 'workerId': user.uid},
        ]),
      });

      // Send notification to the original user who reported the issue
      if (originalUserId.isNotEmpty) {
        try {
          await _notificationService.notifyUserTaskStarted(
            reportId: reportId,
            userId: originalUserId,
            workerName: workerName,
            taskTitle: taskTitle,
          );
          print('Notification sent to user $originalUserId for task started');
        } catch (notificationError) {
          print('Warning: Failed to send notification: $notificationError');
          // Continue execution even if notification fails
        }
      }

      print('Assigned task started successfully'); // Debug log

      // Trigger real-time sync with improved error handling
      try {
        await _triggerRealTimeSync(reportId, 'active');
        print(
          'Real-time sync triggered for task $reportId changing to active status',
        );
      } catch (syncError) {
        print('Warning: Failed to trigger real-time sync: $syncError');
        // Continue execution even if sync fails - the database update is more important
      }
    } catch (e) {
      print('Error starting assigned task: $e'); // Debug log
      throw 'Error starting assigned task: $e';
    }
  }

  // Worker completes an assigned task (moves from active to completed)
  Future<Map<String, dynamic>> completeAssignedTask(
    String reportId, {
    Map<String, dynamic>? completionData,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      print('Worker completing assigned task: $reportId'); // Debug log

      // Get report data for notification
      DocumentSnapshot reportDoc = await _firestore
          .collection('reports')
          .doc(reportId)
          .get();
      if (!reportDoc.exists) throw 'Report not found';

      Map<String, dynamic> reportData =
          reportDoc.data() as Map<String, dynamic>;
      String originalUserId = reportData['userId'] ?? '';
      String taskTitle = reportData['title'] ?? 'Your reported issue';

      // Get worker's name for notification
      DocumentSnapshot workerDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      String workerName = 'A worker';
      if (workerDoc.exists && workerDoc.data() != null) {
        Map<String, dynamic> workerData =
            workerDoc.data() as Map<String, dynamic>;
        workerName = workerData['username'] ?? 'A worker';
      }

      // Get the current timestamp manually
      final timestamp = Timestamp.now();

      // Prepare base update data
      Map<String, dynamic> updateData = {
        'municipalStatus': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'Completed by Worker',
      };

      // If completion data with evidence is provided, add it to the update
      if (completionData != null) {
        // Add evidence location data
        if (completionData['location'] != null) {
          Position position = completionData['location'];
          updateData['completionLocation'] = {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
            'timestamp': timestamp,
          };
        }

        // Add AI analysis data if available
        if (completionData['analysis'] != null) {
          updateData['completionAnalysis'] = completionData['analysis'];
        }
      }

      // Upload image evidence if available
      String? completionImageUrl;

      if (completionData != null) {
        if (completionData['webImageBytes'] != null ||
            completionData['imageFile'] != null) {
          try {
            Reference ref = FirebaseStorage.instance.ref().child(
              'task_completions/${reportId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );

            UploadTask uploadTask;

            if (kIsWeb && completionData['webImageBytes'] != null) {
              uploadTask = ref.putData(completionData['webImageBytes']);
            } else if (completionData['imageFile'] != null) {
              uploadTask = ref.putFile(completionData['imageFile']);
            } else {
              throw 'No valid image data for upload';
            }

            // Wait for upload to complete
            final snapshot = await uploadTask;
            completionImageUrl = await snapshot.ref.getDownloadURL();

            // Add image URL to update data
            updateData['completionImageUrl'] = completionImageUrl;
            print('Completion image uploaded: $completionImageUrl');
          } catch (e) {
            print(
              'Warning: Image upload failed but continuing with completion: $e',
            );
            // Continue with task completion even if image upload fails
          }
        }
      }

      // First update the document without the taskHistory
      await _firestore.collection('reports').doc(reportId).update(updateData);

      // Then update the taskHistory with the manually created timestamp
      await _firestore.collection('reports').doc(reportId).update({
        'taskHistory': FieldValue.arrayUnion([
          {
            'action': 'completed',
            'timestamp': timestamp,
            'workerId': user.uid,
            'hasEvidence': completionImageUrl != null,
            'imageUrl': completionImageUrl,
          },
        ]),
      });

      print('Assigned task completed successfully with evidence'); // Debug log

      // Send notification to the original user who reported the issue
      if (originalUserId.isNotEmpty) {
        try {
          await _notificationService.notifyUserTaskCompleted(
            reportId: reportId,
            userId: originalUserId,
            workerName: workerName,
            taskTitle: taskTitle,
          );
          print('Notification sent to user $originalUserId for task completed');
        } catch (notificationError) {
          print('Warning: Failed to send notification: $notificationError');
          // Continue execution even if notification fails
        }
      }

      // Trigger real-time sync
      await _triggerRealTimeSync(reportId, 'completed');

      // Return success status with additional data
      return {
        'success': true,
        'reportId': reportId,
        'completedAt': timestamp,
        'imageUrl': completionImageUrl,
      };
    } catch (e) {
      print('Error completing assigned task: $e'); // Debug log
      return {'success': false, 'error': 'Error completing task: $e'};
    }
  }

  // Assign task to worker (moves from pending to assigned)
  Future<void> assignTaskToWorker({
    required String reportId,
    required String workerId,
    required String workerName,
    required String department,
    String? estimatedDuration,
    String? notes,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      print('Assigning task $reportId to worker $workerId'); // Debug log

      // First update the document without the taskHistory
      await _firestore.collection('reports').doc(reportId).update({
        'municipalStatus': 'assigned',
        'assignedWorkerId': workerId,
        'assignedWorkerName': workerName,
        'assignedDepartment': department,
        'assignedAt': FieldValue.serverTimestamp(),
        'assignedBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'Assigned to Worker',
        'estimatedDuration': estimatedDuration ?? '3 days',
        'assignmentNotes': notes,
      });

      // Get the current timestamp manually
      final timestamp = Timestamp.now();

      // Then update the taskHistory with the manually created timestamp
      await _firestore.collection('reports').doc(reportId).update({
        'taskHistory': FieldValue.arrayUnion([
          {
            'action': 'assigned',
            'timestamp': timestamp,
            'assignedBy': user.uid,
            'assignedTo': workerId,
            'department': department,
          },
        ]),
      });

      print('Task assigned successfully'); // Debug log

      // Trigger real-time sync
      await _triggerRealTimeSync(reportId, 'assigned');
    } catch (e) {
      print('Error assigning task: $e'); // Debug log
      throw 'Error assigning task: $e';
    }
  }

  // Get tasks in different states for municipal dashboard
  Stream<QuerySnapshot> getMunicipalAssignedTasks() {
    try {
      return _firestore
          .collection('reports')
          .where('municipalStatus', isEqualTo: 'assigned')
          .snapshots();
    } catch (e) {
      print('Error getting assigned tasks: $e'); // Debug log
      return const Stream.empty();
    }
  }

  Stream<QuerySnapshot> getAcceptedTasks() {
    try {
      return _firestore
          .collection('reports')
          .where('municipalStatus', isEqualTo: 'accepted')
          .snapshots();
    } catch (e) {
      print('Error getting accepted tasks: $e'); // Debug log
      return const Stream.empty();
    }
  }

  Stream<QuerySnapshot> getInProgressTasks() {
    try {
      return _firestore
          .collection('reports')
          .where('municipalStatus', whereIn: ['active', 'in-progress'])
          .snapshots();
    } catch (e) {
      print('Error getting in-progress tasks: $e'); // Debug log
      return const Stream.empty();
    }
  }

  // Get tasks by department for sidebar filtering
  Stream<QuerySnapshot> getTasksByDepartment(String department) {
    try {
      return _firestore
          .collection('reports')
          .where('assignedDepartment', isEqualTo: department)
          .snapshots();
    } catch (e) {
      print('Error getting tasks by department: $e'); // Debug log
      return const Stream.empty();
    }
  }

  // Get tasks assigned to a specific worker with filtering by status
  Stream<QuerySnapshot> getWorkerTasksByStatusDetailed(
    String workerId,
    List<String> statuses,
  ) {
    try {
      return _firestore
          .collection('reports')
          .where('assignedWorkerId', isEqualTo: workerId)
          .where('municipalStatus', whereIn: statuses)
          .snapshots();
    } catch (e) {
      print('Error getting worker tasks by status: $e'); // Debug log
      return const Stream.empty();
    }
  }

  // Trigger real-time synchronization
  Future<void> _triggerRealTimeSync(String reportId, String newStatus) async {
    try {
      // Use Timestamp.now() instead of FieldValue.serverTimestamp() with set()
      final timestamp = Timestamp.now();

      // Update a sync collection to notify all dashboards of changes
      await _firestore.collection('task_sync').doc(reportId).set({
        'reportId': reportId,
        'newStatus': newStatus,
        'syncTimestamp': timestamp,
        'syncId': DateTime.now().millisecondsSinceEpoch.toString(),
      }, SetOptions(merge: true));

      print(
        'Real-time sync triggered for report $reportId with status $newStatus',
      );
    } catch (e) {
      print('Error triggering real-time sync: $e');
    }
  }

  // Start a task
  Future<void> startTask(String reportId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      print('Starting task: $reportId'); // Debug log

      await _firestore.collection('reports').doc(reportId).update({
        'municipalStatus': 'active',
        'assignedOfficer': user.uid,
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'In Progress',
      });

      print('Task started successfully'); // Debug log
    } catch (e) {
      print('Error starting task: $e'); // Debug log
      throw 'Error starting task: $e';
    }
  }

  // Complete a task
  Future<void> completeTask(String reportId) async {
    try {
      print('Completing task: $reportId'); // Debug log

      await _firestore.collection('reports').doc(reportId).update({
        'municipalStatus': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'Resolved',
      });

      print('Task completed successfully'); // Debug log
    } catch (e) {
      print('Error completing task: $e'); // Debug log
      throw 'Error completing task: $e';
    }
  }

  // Debug method to test connection
  Future<void> testConnection() async {
    try {
      User? user = _auth.currentUser;
      print('Current user: ${user?.uid}');
      print('User email: ${user?.email}');

      // Test reading reports
      QuerySnapshot snapshot = await _firestore
          .collection('reports')
          .limit(5)
          .get();

      print('Found ${snapshot.docs.length} reports in database');

      for (var doc in snapshot.docs) {
        print('Report ID: ${doc.id}');
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('Report data: $data');
      }
    } catch (e) {
      print('Connection test error: $e');
    }
  }

  // Comprehensive data validation and sync check
  Future<Map<String, dynamic>> validateDataSync() async {
    Map<String, dynamic> syncStatus = {
      'isValid': false,
      'totalReports': 0,
      'pendingReports': 0,
      'activeReports': 0,
      'completedReports': 0,
      'assignedReports': 0,
      'newReports24h': 0,
      'errors': <String>[],
      'warnings': <String>[],
      'lastSyncCheck': DateTime.now().toIso8601String(),
    };

    try {
      // Check total reports
      QuerySnapshot totalSnapshot = await _firestore
          .collection('reports')
          .get();
      syncStatus['totalReports'] = totalSnapshot.docs.length;
      print(
        'Data Sync Validation: Total reports: ${totalSnapshot.docs.length}',
      );

      // Check pending reports
      QuerySnapshot pendingSnapshot = await _firestore
          .collection('reports')
          .where('municipalStatus', isEqualTo: 'pending')
          .get();
      syncStatus['pendingReports'] = pendingSnapshot.docs.length;
      print(
        'Data Sync Validation: Pending reports: ${pendingSnapshot.docs.length}',
      );

      // Check active reports
      QuerySnapshot activeSnapshot = await _firestore
          .collection('reports')
          .where('municipalStatus', isEqualTo: 'active')
          .get();
      syncStatus['activeReports'] = activeSnapshot.docs.length;

      // Check completed reports
      QuerySnapshot completedSnapshot = await _firestore
          .collection('reports')
          .where('municipalStatus', isEqualTo: 'completed')
          .get();
      syncStatus['completedReports'] = completedSnapshot.docs.length;

      // Check assigned reports
      QuerySnapshot assignedSnapshot = await _firestore
          .collection('reports')
          .where('assignedWorkerId', isNull: false)
          .get();
      syncStatus['assignedReports'] = assignedSnapshot.docs.length;

      // Check newly reported (last 24 hours)
      DateTime yesterday = DateTime.now().subtract(const Duration(hours: 24));
      QuerySnapshot newReportsSnapshot = await _firestore
          .collection('reports')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
          .get();
      syncStatus['newReports24h'] = newReportsSnapshot.docs.length;

      // Data validation checks
      List<String> errors = [];
      List<String> warnings = [];

      // Check for reports with missing essential fields
      for (var doc in totalSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['municipalStatus'] == null) {
          errors.add('Report ${doc.id} missing municipalStatus field');
        }
        if (data['issueType'] == null || data['issueType'].toString().isEmpty) {
          errors.add('Report ${doc.id} missing or empty issueType field');
        }
        if (data['createdAt'] == null) {
          warnings.add('Report ${doc.id} missing createdAt timestamp');
        }
        if (data['userId'] == null || data['userId'].toString().isEmpty) {
          warnings.add('Report ${doc.id} missing userId field');
        }
      }

      syncStatus['errors'] = errors;
      syncStatus['warnings'] = warnings;
      syncStatus['isValid'] = errors.isEmpty;

      print(
        'Data Sync Validation completed: ${syncStatus['isValid'] ? 'VALID' : 'INVALID'}',
      );
      if (errors.isNotEmpty) {
        print('Data Sync Validation errors: $errors');
      }
      if (warnings.isNotEmpty) {
        print('Data Sync Validation warnings: $warnings');
      }
    } catch (e) {
      syncStatus['errors'].add('Sync validation failed: $e');
      print('Data Sync Validation failed: $e');
    }

    return syncStatus;
  }

  // Force refresh all dashboard streams
  Future<void> forceRefreshDashboard() async {
    try {
      print('Forcing dashboard refresh...');
      // Trigger a write operation that doesn't change data but forces stream refresh
      await _firestore.collection('system').doc('dashboard_refresh').set({
        'lastRefresh': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('Dashboard refresh triggered');
    } catch (e) {
      print('Error forcing dashboard refresh: $e');
    }
  }

  // Check if a report was recently submitted (within last 5 minutes)
  bool isNewlyReported(Map<String, dynamic> reportData) {
    try {
      Timestamp? createdAt = reportData['createdAt'] as Timestamp?;
      if (createdAt == null) return false;

      DateTime createdDate = createdAt.toDate();
      DateTime fiveMinutesAgo = DateTime.now().subtract(
        const Duration(minutes: 5),
      );

      return createdDate.isAfter(fiveMinutesAgo);
    } catch (e) {
      print('Error checking if newly reported: $e');
      return false;
    }
  }

  // Fix missing municipalStatus fields in existing reports
  Future<void> fixMissingMunicipalStatus() async {
    try {
      print('Starting to fix missing municipalStatus fields...');

      // Get all reports
      QuerySnapshot allReports = await _firestore.collection('reports').get();

      int fixedCount = 0;
      List<String> batchIds = [];
      WriteBatch batch = _firestore.batch();

      for (var doc in allReports.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Check if municipalStatus is missing or null
        if (data['municipalStatus'] == null || data['municipalStatus'] == '') {
          String newStatus = 'pending'; // Default status

          // Try to determine appropriate status based on existing fields
          if (data['status'] != null) {
            String status = data['status'].toString().toLowerCase();
            if (status.contains('progress') || status.contains('active')) {
              newStatus = 'active';
            } else if (status.contains('completed') ||
                status.contains('resolved')) {
              newStatus = 'completed';
            } else if (status.contains('assigned')) {
              newStatus = 'assigned';
            }
          }

          // Update the document
          batch.update(doc.reference, {
            'municipalStatus': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          batchIds.add(doc.id);
          fixedCount++;

          print(
            'Fixing report ${doc.id}: Setting municipalStatus to $newStatus',
          );

          // Execute batch every 500 operations (Firestore limit)
          if (fixedCount % 500 == 0) {
            await batch.commit();
            batch = _firestore.batch();
            print('Committed batch of $fixedCount fixes...');
          }
        }
      }

      // Commit remaining operations
      if (batchIds.isNotEmpty) {
        await batch.commit();
        print('Committed final batch');
      }

      print(
        'Successfully fixed $fixedCount reports with missing municipalStatus fields',
      );
    } catch (e) {
      print('Error fixing missing municipalStatus fields: $e');
      throw 'Error fixing missing municipalStatus fields: $e';
    }
  }

  // Delete a completed task/report
  Future<void> deleteCompletedTask(String reportId) async {
    try {
      print('Deleting completed task: $reportId');

      // First verify the task is completed before allowing deletion
      DocumentSnapshot doc = await _firestore
          .collection('reports')
          .doc(reportId)
          .get();

      if (!doc.exists) {
        throw 'Task not found';
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String municipalStatus = data['municipalStatus']?.toString() ?? '';

      if (municipalStatus != 'completed') {
        throw 'Only completed tasks can be deleted';
      }

      // Delete the document
      await _firestore.collection('reports').doc(reportId).delete();

      print('Successfully deleted completed task: $reportId');
    } catch (e) {
      print('Error deleting task: $e');
      throw 'Error deleting task: $e';
    }
  }
}
