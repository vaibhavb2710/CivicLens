import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser?.uid;
    if (currentUserId != null) {
      // Mark all notifications as read when opening the screen
      _notificationService.markAllNotificationsAsRead(currentUserId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
        body: const Center(
          child: Text('Please log in to view notifications'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _showClearAllDialog,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationService.getUserNotifications(currentUserId!),
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
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see updates about your reported issues here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Sort notifications on the client side by timestamp
          List<DocumentSnapshot> sortedDocs = snapshot.data!.docs.toList();
          sortedDocs.sort((a, b) {
            Timestamp? timeA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            Timestamp? timeB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            
            if (timeA == null && timeB == null) return 0;
            if (timeA == null) return 1;
            if (timeB == null) return -1;
            
            // Sort in descending order (newest first)
            return timeB.compareTo(timeA);
          });
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = sortedDocs[index];
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              return _buildNotificationCard(doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(String notificationId, Map<String, dynamic> data) {
    bool isRead = data['isRead'] ?? false;
    String type = data['type'] ?? '';
    String title = data['title'] ?? '';
    String message = data['message'] ?? '';
    Timestamp? createdAt = data['createdAt'];

    IconData iconData;
    Color iconColor;
    Color cardColor;

    switch (type) {
      case 'task_started':
        iconData = Icons.play_circle;
        iconColor = Colors.blue;
        cardColor = Colors.blue[50]!;
        break;
      case 'task_completed':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        cardColor = Colors.green[50]!;
        break;
      case 'task_assigned':
        iconData = Icons.assignment;
        iconColor = Colors.orange;
        cardColor = Colors.orange[50]!;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
        cardColor = Colors.grey[50]!;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      color: isRead ? Colors.white : cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRead ? Colors.grey[200]! : iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!isRead) {
            _notificationService.markNotificationAsRead(notificationId);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: iconColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formatTimestamp(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey[600],
                  size: 20,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'delete':
                      _deleteNotification(notificationId);
                      break;
                    case 'mark_read':
                      if (!isRead) {
                        _notificationService.markNotificationAsRead(notificationId);
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!isRead)
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read, size: 18),
                          SizedBox(width: 8),
                          Text('Mark as read'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _deleteNotification(String notificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _notificationService.deleteNotification(notificationId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to mark all notifications as read?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (currentUserId != null) {
                _notificationService.markAllNotificationsAsRead(currentUserId!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}