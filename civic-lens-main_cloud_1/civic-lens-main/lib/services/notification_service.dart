import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a notification for a user
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type, // 'task_started', 'task_completed', 'task_assigned', etc.
    String? taskId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'taskId': taskId,
        'additionalData': additionalData,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('Notification created for user $userId: $title'); // Debug log
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Send notification when worker starts a task
  Future<void> notifyUserTaskStarted({
    required String reportId,
    required String userId,
    required String workerName,
    required String taskTitle,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Task Started',
      message: 'Worker $workerName has started working on your reported issue: $taskTitle',
      type: 'task_started',
      taskId: reportId,
      additionalData: {
        'workerName': workerName,
        'taskTitle': taskTitle,
      },
    );
  }

  // Send notification when worker completes a task
  Future<void> notifyUserTaskCompleted({
    required String reportId,
    required String userId,
    required String workerName,
    required String taskTitle,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Task Completed',
      message: 'Worker $workerName has completed work on your reported issue: $taskTitle',
      type: 'task_completed',
      taskId: reportId,
      additionalData: {
        'workerName': workerName,
        'taskTitle': taskTitle,
      },
    );
  }

  // Get notifications for current user
  // Modified to use separate queries to avoid composite index requirements
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    // First query just filters by userId without ordering
    try {
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .snapshots();
    } catch (e) {
      print('Error in getUserNotifications: $e');
      // Fallback to even simpler query if needed
      return _firestore
          .collection('notifications')
          .snapshots();
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for current user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      QuerySnapshot unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Clean up old notifications (older than 30 days)
  Future<void> cleanupOldNotifications() async {
    try {
      DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      Timestamp cutoffTime = Timestamp.fromDate(thirtyDaysAgo);

      QuerySnapshot oldNotifications = await _firestore
          .collection('notifications')
          .where('createdAt', isLessThan: cutoffTime)
          .get();

      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('Cleaned up ${oldNotifications.docs.length} old notifications');
    } catch (e) {
      print('Error cleaning up old notifications: $e');
    }
  }
}