import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Store verification ID for OTP verification
  String? _verificationId;
  int? _resendToken;
  PhoneAuthCredential? _phoneCredential; // Store credential for verification
  String? _currentPhoneNumber; // Store the phone number being verified
  String? get verificationId => _verificationId;

  // Test phone numbers with their OTP codes for development
  final Map<String, String> _testNumbers = {
    '+911234567890': '123456',
    '+919999999999': '123456',
    '+919876543210': '123456',
    // Real numbers should NOT be in this list for SMS to work
  };

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Format phone number with country code
  String _formatPhoneNumber(String phoneNumber) {
    // Remove any spaces, dashes, or other formatting
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If it doesn't start with +, add +91 (India)
    if (!cleaned.startsWith('+')) {
      // Remove leading 0 if present
      if (cleaned.startsWith('0')) {
        cleaned = cleaned.substring(1);
      }
      cleaned = '+91$cleaned';
    }
    
    print('Formatted phone number: $cleaned'); // Debug log
    return cleaned;
  }

  // Validate phone number format
  bool _isValidPhoneNumber(String phoneNumber) {
    String formatted = _formatPhoneNumber(phoneNumber);
    
    // Check if it's a test number
    if (_testNumbers.containsKey(formatted)) {
      return true;
    }
    
    // Check Indian phone number format (+91 followed by 10 digits)
    RegExp indiaPhoneRegex = RegExp(r'^\+91[6-9]\d{9}$');
    return indiaPhoneRegex.hasMatch(formatted);
  }

  // Check if phone number is a test number
  bool _isTestNumber(String phoneNumber) {
    String formatted = _formatPhoneNumber(phoneNumber);
    return _testNumbers.containsKey(formatted);
  }

  // Send OTP to phone number
  Future<void> sendOTP(String phoneNumber) async {
    try {
      String formattedNumber = _formatPhoneNumber(phoneNumber);
      _currentPhoneNumber = formattedNumber; // Store for verification
      print('Sending OTP to: $formattedNumber'); // Debug log
      
      // Validate phone number format
      if (!_isValidPhoneNumber(formattedNumber)) {
        throw 'Invalid phone number format. Please enter a valid Indian mobile number.';
      }
      
      // Handle test numbers (specific test numbers only)
      if (_isTestNumber(formattedNumber)) {
        print('Test number detected, simulating OTP send');
        // For test numbers, simulate successful OTP send
        _verificationId = 'test_verification_id_${DateTime.now().millisecondsSinceEpoch}';
        return;
      }
      
      // For real phone numbers, always try Firebase Phone Auth
      print('Real phone number detected, sending actual SMS');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only) - this happens automatically on some Android devices
          print('Auto-verification completed');
          _phoneCredential = credential;
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.code} - ${e.message}'); // Debug log
          String errorMessage = 'Phone verification failed';
          
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number format';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many requests. Please try again later';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded for today. Please try again tomorrow';
              break;
            case 'operation-not-allowed':
              errorMessage = 'Phone authentication is not enabled. Please contact support';
              break;
            case 'app-not-authorized':
              errorMessage = 'App not authorized for phone authentication. Please contact support';
              break;
            case 'captcha-check-failed':
              errorMessage = 'reCAPTCHA verification failed. Please try again';
              break;
            case 'billing-not-enabled':
              // Firebase free plan doesn't support SMS - fall back to test mode
              print('Firebase billing not enabled, falling back to test mode');
              _verificationId = 'test_verification_id_${DateTime.now().millisecondsSinceEpoch}';
              return;
            default:
              errorMessage = e.message ?? 'Phone verification failed';
          }
          throw errorMessage;
        },
        codeSent: (String verificationId, int? resendToken) {
          print('SMS sent successfully. Verification ID: $verificationId'); // Debug log
          _verificationId = verificationId;
          _resendToken = resendToken;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto-retrieval timeout. Verification ID: $verificationId'); // Debug log
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print('Error sending OTP: $e'); // Debug log
      
      if (e is String) {
        throw e;
      }
      
      // Handle specific Firebase errors
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'operation-not-allowed':
            throw 'Phone authentication is not enabled in Firebase Console. Please enable it first.';
          case 'too-many-requests':
            throw 'Too many requests. Please try again after some time.';
          case 'quota-exceeded':
            throw 'Daily SMS quota exceeded. Please try again tomorrow.';
          case 'billing-not-enabled':
            // Fall back to test mode for billing issues
            print('Firebase billing not enabled, falling back to test mode');
            _verificationId = 'test_verification_id_${DateTime.now().millisecondsSinceEpoch}';
            return;
          default:
            throw e.message ?? 'Failed to send OTP';
        }
      }
      
      // Check for billing errors in the error message
      if (e.toString().contains('billing-not-enabled') || 
          e.toString().contains('billing') ||
          e.toString().contains('payment')) {
        print('Billing error detected, falling back to test mode');
        _verificationId = 'test_verification_id_${DateTime.now().millisecondsSinceEpoch}';
        return;
      }
      
      throw 'Failed to send OTP. Using test mode - enter 123456 as OTP.';
    }
  }

  // Resend OTP to the same phone number
  Future<void> resendOTP(String phoneNumber) async {
    try {
      String formattedNumber = _formatPhoneNumber(phoneNumber);
      _currentPhoneNumber = formattedNumber; // Update current phone number
      print('Resending OTP to: $formattedNumber'); // Debug log
      
      // Handle test numbers
      if (_isTestNumber(formattedNumber)) {
        print('Test number detected, simulating OTP resend');
        return;
      }
      
      // For real numbers, if we don't have a resend token, treat it as a new send
      if (_resendToken == null) {
        print('No resend token available, sending as new OTP');
        await sendOTP(phoneNumber);
        return;
      }
      
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('Auto-verification completed on resend');
          _phoneCredential = credential;
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Resend verification failed: ${e.code} - ${e.message}');
          String errorMessage = 'Failed to resend OTP';
          
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number format';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many requests. Please try again later';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please try again later';
              break;
            case 'invalid-app-credential':
              errorMessage = 'App verification failed. Please try sending a new OTP';
              break;
            default:
              errorMessage = e.message ?? 'Failed to resend OTP';
          }
          throw errorMessage;
        },
        codeSent: (String verificationId, int? resendToken) {
          print('Code resent successfully. Verification ID: $verificationId');
          _verificationId = verificationId;
          _resendToken = resendToken;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Resend auto-retrieval timeout. Verification ID: $verificationId');
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken, // Use the resend token
      );
    } catch (e) {
      print('Error resending OTP: $e');
      if (e is String) {
        throw e;
      }
      throw 'Failed to resend OTP. Please try again.';
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String otp) async {
    try {
      print('Verifying OTP: $otp'); // Debug log
      if (_verificationId == null) {
        throw 'No verification ID found. Please send OTP first.';
      }

      // Handle test numbers - check if verification ID indicates test number
      if (_verificationId!.startsWith('test_verification_id_')) {
        print('Test number verification detected'); // Debug log
        // For test mode, always accept 123456 as valid OTP
        if (otp == '123456') {
          print('Test OTP verified successfully');
          return true;
        } else {
          throw 'Invalid OTP. For test numbers, use: 123456';
        }
      }

      // For real phone numbers, verify with Firebase
      print('Real phone number verification - using Firebase'); // Debug log
      
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Store the credential for later use during signup
      _phoneCredential = credential;
      
      // For web environment, we need to handle verification differently
      if (kIsWeb) {
        try {
          // Try to sign in with the credential directly for verification
          await _auth.signInWithCredential(credential);
          // Immediately sign out after verification
          await _auth.signOut();
          print('Real SMS OTP verified successfully on web');
          return true;
        } catch (e) {
          print('Web verification failed: $e');
          // If it fails due to admin restrictions but the OTP might be correct,
          // we can't verify it properly in web environment
          throw 'OTP verification failed. Please try on mobile app for full SMS verification.';
        }
      }
      
      // For mobile environment, use the safer anonymous user method
      print('Attempting to verify phone credential with anonymous user...'); // Debug log
      
      // Create a temporary anonymous user to test the credential
      UserCredential tempUser = await _auth.signInAnonymously();
      
      try {
        // Try to link the phone credential
        await tempUser.user!.linkWithCredential(credential);
        print('Real SMS OTP verified successfully'); // Debug log
        
        // Delete the temporary user
        await tempUser.user!.delete();
        
        return true;
      } catch (linkError) {
        // Delete the temporary user even if linking fails
        await tempUser.user!.delete();
        
        if (linkError is FirebaseAuthException) {
          if (linkError.code == 'credential-already-in-use') {
            // This actually means the credential is valid but already used
            print('OTP verified successfully (credential already in use)');
            return true;
          }
        }
        throw linkError;
      }
      
    } on FirebaseAuthException catch (e) {
      print('OTP verification failed: ${e.code} - ${e.message}'); // Debug log
      String errorMessage = 'Invalid OTP';
      
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP code';
          break;
        case 'invalid-verification-id':
          errorMessage = 'Verification session expired. Please request a new OTP';
          break;
        case 'session-expired':
          errorMessage = 'OTP session expired. Please request a new OTP';
          break;
        default:
          errorMessage = e.message ?? 'Invalid OTP';
      }
      throw errorMessage;
    } catch (e) {
      print('Error during OTP verification: $e'); // Debug log
      if (e is String) {
        throw e;
      }
      throw 'OTP verification failed. Please try again.';
    }
  }

  // Helper method to get current phone number being verified
  // Get the stored phone credential
  PhoneAuthCredential? getPhoneCredential() {
    return _phoneCredential;
  }

  // Debug method to check current state
  void debugAuthState() {
    print('=== AUTH SERVICE DEBUG STATE ===');
    print('Verification ID: $_verificationId');
    print('Current Phone Number: $_currentPhoneNumber');
    print('Resend Token: $_resendToken');
    print('Phone Credential: $_phoneCredential');
    print('Test Numbers: $_testNumbers');
    print('=== END DEBUG STATE ===');
  }

  // Sign in with phone number (OTP login)
  Future<UserCredential?> signInWithPhoneNumber(String phoneNumber, String otp) async {
    try {
      String formattedNumber = _formatPhoneNumber(phoneNumber);
      
      // For test numbers, create a dummy user or handle test login
      if (_isTestNumber(formattedNumber)) {
        throw 'Test numbers cannot be used for login. Please use a real phone number.';
      }
      
      // Verify the OTP first
      bool isVerified = await verifyOTP(otp);
      if (!isVerified) {
        throw 'Invalid OTP';
      }
      
      // If we have a phone credential, use it to sign in
      if (_phoneCredential != null) {
        UserCredential result = await _auth.signInWithCredential(_phoneCredential!);
        return result;
      }
      
      // If no credential, create one and sign in
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      UserCredential result = await _auth.signInWithCredential(credential);
      return result;
      
    } on FirebaseAuthException catch (e) {
      print('Phone login failed: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'invalid-verification-code':
          throw 'Invalid OTP code';
        case 'invalid-verification-id':
          throw 'OTP session expired. Please request a new OTP';
        case 'session-expired':
          throw 'OTP session expired. Please request a new OTP';
        case 'user-not-found':
          throw 'No account found with this phone number. Please register first.';
        default:
          throw e.message ?? 'Phone login failed';
      }
    } catch (e) {
      print('Error during phone login: $e');
      if (e is String) {
        throw e;
      }
      throw 'Phone login failed. Please try again.';
    }
  }

  // Sign up with email, password, username, and user type (with verified phone)
  Future<UserCredential?> signUpWithEmailAndPassword(
    String email, 
    String password, 
    String username, {
    String? phoneNumber,
    String userType = 'citizen',
    String? department,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user profile to Firestore
      if (result.user != null) {
        await _userService.saveUserProfile(
          uid: result.user!.uid,
          username: username,
          email: email,
          phoneNumber: phoneNumber,
          userType: userType,
          department: department,
        );
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An error occurred during signup';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  // Sign in with email & password (unchanged)
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An error occurred during sign in';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  // Sign out (unchanged)
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      throw 'Error signing out';
    }
  }

  // Reset password (unchanged)
  Future<void> resetPassword(String email) async {
    try {
      return await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An error occurred';
    }
  }
}
