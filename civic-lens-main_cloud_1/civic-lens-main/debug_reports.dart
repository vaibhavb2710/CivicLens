// Debug script to check reports in Firestore
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  try {
    print('Checking all reports in Firestore...');
    
    QuerySnapshot allReports = await FirebaseFirestore.instance
        .collection('reports')
        .get();
    
    print('Total reports found: ${allReports.docs.length}');
    
    for (var doc in allReports.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      print('Report ID: ${doc.id}');
      print('  Title: ${data['title']}');
      print('  Municipal Status: ${data['municipalStatus']}');
      print('  Status: ${data['status']}');
      print('  User: ${data['userName']} (${data['userId']})');
      print('  Created: ${data['createdAt']}');
      print('  ---');
    }
    
    // Check specifically for pending reports
    QuerySnapshot pendingReports = await FirebaseFirestore.instance
        .collection('reports')
        .where('municipalStatus', isEqualTo: 'pending')
        .get();
    
    print('Pending reports found: ${pendingReports.docs.length}');
    
  } catch (e) {
    print('Error: $e');
  }
}