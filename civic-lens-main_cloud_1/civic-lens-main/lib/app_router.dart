import 'package:flutter/material.dart';
import 'services/user_service.dart';

class AppRouter {
  static final UserService _userService = UserService();

  // Navigate to appropriate dashboard based on user type
  static Future<void> navigateBasedOnUserType(BuildContext context) async {
    try {
      String userType = await _userService.getCurrentUserType();
      
      switch (userType) {
        case 'worker':
          Navigator.pushReplacementNamed(context, '/workers-dashboard');
          break;
        case 'municipal':
          Navigator.pushReplacementNamed(context, '/municipal-dashboard');
          break;
        case 'citizen':
        default:
          Navigator.pushReplacementNamed(context, '/citizen');
          break;
      }
    } catch (e) {
      // Default to citizen portal if error
      Navigator.pushReplacementNamed(context, '/citizen');
    }
  }
}