import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class TaskSyncService {
  static final TaskSyncService _instance = TaskSyncService._internal();
  factory TaskSyncService() => _instance;
  TaskSyncService._internal();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<TaskSyncEvent> _syncController = StreamController<TaskSyncEvent>.broadcast();
  
  // Stream for real-time task sync events
  Stream<TaskSyncEvent> get syncStream => _syncController.stream;
  
  // Listen to task sync events from Firestore
  StreamSubscription<QuerySnapshot>? _syncSubscription;
  
  void initialize() {
    _syncSubscription = _firestore
        .collection('task_sync')
        .snapshots()
        .listen(_handleSyncEvent);
  }
  
  void dispose() {
    _syncSubscription?.cancel();
    _syncController.close();
  }
  
  void _handleSyncEvent(QuerySnapshot snapshot) {
    for (var docChange in snapshot.docChanges) {
      if (docChange.type == DocumentChangeType.added || 
          docChange.type == DocumentChangeType.modified) {
        
        Map<String, dynamic> data = docChange.doc.data() as Map<String, dynamic>;
        
        // Check if we have all required fields
        if (data['reportId'] != null && data['newStatus'] != null && data['syncId'] != null) {
          TaskSyncEvent event = TaskSyncEvent(
            reportId: data['reportId'],
            newStatus: data['newStatus'],
            syncTimestamp: data['syncTimestamp'] as Timestamp?,
            syncId: data['syncId'],
          );
          
          print('Processing sync event: ${event.toString()}');
          _syncController.add(event);
        } else {
          print('Warning: Received invalid sync event data: $data');
        }
      }
    }
  }
  
  // Trigger a sync event for real-time updates
  Future<void> triggerSync(String reportId, String newStatus) async {
    try {
      // Use Timestamp.now() instead of FieldValue.serverTimestamp() with set()
      final timestamp = Timestamp.now();
      final syncId = DateTime.now().millisecondsSinceEpoch.toString();
      
      print('Triggering sync for report $reportId with new status: $newStatus (syncId: $syncId)');
      
      await _firestore.collection('task_sync').doc(reportId).set({
        'reportId': reportId,
        'newStatus': newStatus,
        'syncTimestamp': timestamp,
        'syncId': syncId,
      }, SetOptions(merge: true));
      
      print('Sync event created successfully for report $reportId');
      
      // Ensure the sync event is immediately processed by adding it directly to the stream
      _syncController.add(TaskSyncEvent(
        reportId: reportId,
        newStatus: newStatus,
        syncTimestamp: timestamp,
        syncId: syncId,
      ));
      
    } catch (e) {
      print('Error triggering sync: $e');
      throw 'Error triggering sync: $e';
    }
  }
  
  // Clean up old sync events (call periodically)
  Future<void> cleanupOldSyncEvents() async {
    try {
      DateTime oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      Timestamp cutoff = Timestamp.fromDate(oneDayAgo);
      
      QuerySnapshot oldEvents = await _firestore
          .collection('task_sync')
          .where('syncTimestamp', isLessThan: cutoff)
          .get();
      
      WriteBatch batch = _firestore.batch();
      for (var doc in oldEvents.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('Cleaned up ${oldEvents.docs.length} old sync events');
    } catch (e) {
      print('Error cleaning up sync events: $e');
    }
  }
}

class TaskSyncEvent {
  final String reportId;
  final String newStatus;
  final Timestamp? syncTimestamp;
  final String syncId;
  
  TaskSyncEvent({
    required this.reportId,
    required this.newStatus,
    this.syncTimestamp,
    required this.syncId,
  });
  
  @override
  String toString() {
    return 'TaskSyncEvent(reportId: $reportId, newStatus: $newStatus, syncId: $syncId)';
  }
}

// Task status constants for consistency
class TaskStatus {
  static const String pending = 'pending';
  static const String assigned = 'assigned';
  static const String active = 'active';
  static const String completed = 'completed';
  
  static List<String> get allStatuses => [pending, assigned, active, completed];
  
  static String getDisplayName(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case assigned:
        return 'Assigned';
      case active:
        return 'Active';
      case completed:
        return 'Completed';
      default:
        return status;
    }
  }
  
  static String getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case pending:
        return assigned;
      case assigned:
        return active;
      case active:
        return completed;
      default:
        return currentStatus;
    }
  }
}