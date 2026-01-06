import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'role_selection_screen.dart';
import 'auth_wrapper.dart';
import 'home_widget.dart';
import 'report_issue_screen.dart';
import 'notifications_screen.dart';
import 'municipal/municipal_auth_wrapper.dart';
import 'workers/workers_dashboard.dart';
import 'services/task_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize the task sync service for real-time updates
  TaskSyncService().initialize();

  // Clean up old sync events on startup
  TaskSyncService().cleanupOldSyncEvents();

  runApp(CivicLensApp());
}

class CivicLensApp extends StatelessWidget {
  const CivicLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Civic Lens',
      theme: ThemeData(
        primaryColor: const Color(0xFF8B7355),
        scaffoldBackgroundColor: const Color(0xFFF5F3F0),
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const RoleSelectionScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/login': (context) => const RoleSelectionScreen(),
        '/citizen': (context) => const AuthWrapper(),
        '/home': (context) => const HomeWidget(),
        '/report': (context) => const ReportIssueScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/municipal-dashboard': (context) => const MunicipalAuthWrapper(),
        '/workers-dashboard': (context) => const WorkersDashboard(),
      },
    );
  }
}
