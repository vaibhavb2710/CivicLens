import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/user_service.dart';
import 'role_selection_screen.dart';
import 'home_widget.dart';
import 'workers/workers_dashboard.dart';
import 'municipal/municipal_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasData) {
            return FutureBuilder<String?>(
              future: UserService().getCurrentUserType(),
              builder: (context, userTypeSnapshot) {
                if (userTypeSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (userTypeSnapshot.hasData) {
                  final userType = userTypeSnapshot.data;
                  switch (userType) {
                    case 'citizen':
                      return const HomeWidget();
                    case 'worker':
                      return const WorkersDashboard();
                    case 'municipal':
                      return const MunicipalDashboard();
                    default:
                      return const RoleSelectionScreen();
                  }
                } else {
                  return const RoleSelectionScreen();
                }
              },
            );
          } else {
            return const RoleSelectionScreen();
          }
        },
      ),
    );
  }
}
