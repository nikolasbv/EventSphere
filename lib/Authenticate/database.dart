import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String uid;
  DatabaseService({required this.uid});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(String email, String username) async {
    try {
      await _firestore.collection('Users').doc(uid).set({
        'email': email,
        'username': username,
        'likedEvents': [],
        'bookmarkedEvents': [],
        'myEvents': [],
        'dislikedEvents': [],
        'publishedEvents': [],
        'savedEvents': [],
        'homeEvents': []
      });
      print('User created successfully.');
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  Future<DocumentReference> createEvent(Map<String, dynamic> eventData) async {
    return await _firestore.collection('events').add(eventData);
  }
}
