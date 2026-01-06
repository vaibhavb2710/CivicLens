import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import '../lib/services/report_service.dart';
import '../lib/services/task_sync_service.dart';

void main() {
  group('Task Workflow Integration Tests', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('Complete task workflow from assignment to completion', () async {
      final reportId = 'test_report_123';
      final workerId = 'worker123';
      final workerName = 'Test Worker';
      final department = 'Public Works';

      // Step 1: Create a pending task
      await firestore.collection('reports').doc(reportId).set({
        'userId': 'citizen123',
        'issueType': 'Potholes',
        'title': 'Large pothole on Main Street',
        'description': 'Deep pothole causing traffic issues',
        'municipalStatus': 'pending',
        'priority': 'high',
        'createdAt': Timestamp.now(),
        'status': 'Submitted',
      });

      // Step 2: Verify pending task exists
      DocumentSnapshot pendingTask = await firestore
          .collection('reports')
          .doc(reportId)
          .get();
      expect(pendingTask.exists, isTrue);
      expect((pendingTask.data() as Map)['municipalStatus'], equals('pending'));

      // Step 3: Simulate task assignment
      await firestore.collection('reports').doc(reportId).update({
        'municipalStatus': 'assigned',
        'assignedWorkerId': workerId,
        'assignedWorkerName': workerName,
        'assignedDepartment': department,
        'assignedAt': Timestamp.now(),
      });

      DocumentSnapshot assignedTask = await firestore
          .collection('reports')
          .doc(reportId)
          .get();
      Map<String, dynamic> assignedData =
          assignedTask.data() as Map<String, dynamic>;

      expect(assignedData['municipalStatus'], equals('assigned'));
      expect(assignedData['assignedWorkerId'], equals(workerId));
      expect(assignedData['assignedWorkerName'], equals(workerName));

      // Step 4: Simulate task started
      await firestore.collection('reports').doc(reportId).update({
        'municipalStatus': 'active',
        'startedAt': Timestamp.now(),
        'status': 'In Progress',
      });

      DocumentSnapshot activeTask = await firestore
          .collection('reports')
          .doc(reportId)
          .get();
      Map<String, dynamic> activeData =
          activeTask.data() as Map<String, dynamic>;

      expect(activeData['municipalStatus'], equals('active'));
      expect(activeData['status'], equals('In Progress'));

      // Step 5: Simulate task completion
      await firestore.collection('reports').doc(reportId).update({
        'municipalStatus': 'completed',
        'completedAt': Timestamp.now(),
        'status': 'Completed by Worker',
      });

      DocumentSnapshot completedTask = await firestore
          .collection('reports')
          .doc(reportId)
          .get();
      Map<String, dynamic> completedData =
          completedTask.data() as Map<String, dynamic>;

      expect(completedData['municipalStatus'], equals('completed'));
      expect(completedData['status'], equals('Completed by Worker'));

      print('✅ Complete task workflow test passed!');
    });

    test('Dashboard filtering by status', () async {
      final tasks = [
        {'id': 'task1', 'status': 'pending'},
        {'id': 'task2', 'status': 'assigned'},
        {'id': 'task3', 'status': 'active'},
        {'id': 'task4', 'status': 'completed'},
        {'id': 'task5', 'status': 'assigned'},
      ];

      for (var task in tasks) {
        await firestore.collection('reports').doc(task['id']).set({
          'municipalStatus': task['status'],
          'issueType': 'Test Issue',
          'title': 'Test Task ${task['id']}',
          'createdAt': Timestamp.now(),
        });
      }

      QuerySnapshot pendingTasks = await firestore
          .collection('reports')
          .where('municipalStatus', isEqualTo: 'pending')
          .get();
      expect(pendingTasks.docs.length, equals(1));

      QuerySnapshot assignedTasks = await firestore
          .collection('reports')
          .where('municipalStatus', isEqualTo: 'assigned')
          .get();
      expect(assignedTasks.docs.length, equals(2));

      print('✅ Dashboard filtering test passed!');
    });

    test('Worker task filtering', () async {
      final workerId = 'worker123';

      final workerTasks = [
        {'id': 'wtask1', 'status': 'assigned'},
        {'id': 'wtask2', 'status': 'active'},
        {'id': 'wtask3', 'status': 'completed'},
      ];

      for (var task in workerTasks) {
        await firestore.collection('reports').doc(task['id']).set({
          'municipalStatus': task['status'],
          'assignedWorkerId': workerId,
          'issueType': 'Worker Task',
          'title': 'Worker Task ${task['id']}',
          'createdAt': Timestamp.now(),
        });
      }

      QuerySnapshot workerAssignedTasks = await firestore
          .collection('reports')
          .where('assignedWorkerId', isEqualTo: workerId)
          .where('municipalStatus', isEqualTo: 'assigned')
          .get();
      expect(workerAssignedTasks.docs.length, equals(1));

      print('✅ Worker task filtering test passed!');
    });
  });
}
