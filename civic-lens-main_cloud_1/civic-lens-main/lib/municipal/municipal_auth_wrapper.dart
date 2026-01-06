import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'municipal_dashboard.dart';

class MunicipalAuthWrapper extends StatelessWidget {
  const MunicipalAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F3F0),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF8B7355)),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const MunicipalDashboard();
        }

        // Not authenticated, redirect to role selection with municipal tab pre-selected
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/role-selection');
        });
        
        return const Scaffold(
          backgroundColor: Color(0xFFF5F3F0),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF8B7355)),
          ),
        );
      },
    );
  }
}