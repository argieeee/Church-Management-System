import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date, required String userID,
  });

  factory Event.fromFirestore(Map<String, dynamic> data, String id) {
    return Event(
      id: id,
      title: data['title'],
      description: data['description'],
      date: (data['date'] as Timestamp).toDate(), userID: '',
    );
  }

  updateEvent({required String title, required String description, required DateTime date, required String userID}) {}
}


  // Add method to convert Event object to Firestore data
  Future<void> updateEvent({
    required String title,
    required String description,
    required DateTime date,
    required String userID, // Pass userID
  }) async {
    try {
      await FirebaseFirestore.instance.collection('events').doc(userID).update({
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(date),
        'userID': userID, // Ensure userID is updated
      });
    } catch (e) {
      print('Error updating event: $e');
      rethrow;
    }
  }

