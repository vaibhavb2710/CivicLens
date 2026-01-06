import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save user profile after registration
  Future<void> saveUserProfile({
    required String uid,
    required String username,
    required String email,
    String? phoneNumber,
    String userType = 'citizen', // citizen, worker, municipal
    String? department, // Department for workers
  }) async {
    try {
      Map<String, dynamic> userData = {
        'username': username,
        'email': email,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        userData['phoneNumber'] = phoneNumber;
      }
      
      if (department != null && userType == 'worker') {
        userData['department'] = department;
      }
      
      await _firestore.collection('users').doc(uid).set(userData);
    } catch (e) {
      throw 'Error saving user profile: $e';
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      throw 'Error fetching user profile: $e';
    }
  }

  // Get current user's username
  Future<String> getCurrentUsername() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return 'User';

      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        return userData['username'] ?? 'User';
      }
      return 'User';
    } catch (e) {
      return 'User';
    }
  }

  // Get current user's type
  Future<String> getCurrentUserType() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return 'citizen';

      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        return userData['userType'] ?? 'citizen';
      }
      return 'citizen';
    } catch (e) {
      return 'citizen';
    }
  }

  // Get workers by department
  Stream<QuerySnapshot> getWorkersByDepartment(String department) {
    try {
      return _firestore
          .collection('users')
          .where('userType', isEqualTo: 'worker')
          .where('department', isEqualTo: department)
          .snapshots();
    } catch (e) {
      return const Stream.empty();
    }
  }

  // Get all workers
  Stream<QuerySnapshot> getAllWorkers() {
    try {
      return _firestore
          .collection('users')
          .where('userType', isEqualTo: 'worker')
          .snapshots();
    } catch (e) {
      return const Stream.empty();
    }
  }

  // Get current user's department (for workers)
  Future<String?> getCurrentUserDepartment() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        return userData['department'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
