import 'dart:async';
import 'dart:developer';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserStorage {
  //TODO write database for all users
  final FirebaseFirestore db = FirebaseFirestore.instance;


  Future<void> storeNotification(String title, String body) async {
    try {
      int notificationId = DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF;
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'channelKey',
          title: title,
          body: body,
        ),
      );
    } catch (e) {
      log("Error storing notification: $e");
    }
  }


  Future<void> createUser(String uniqueID,
      Map<String, String> userInformation,String type) async {
    try {
      db.collection("users")
          .doc(type)
          .collection(uniqueID)
          .doc("About User")
          .set(userInformation);
    }
    catch (e) {
      log("Error code STORAGE: $e");
    }
  }

  Future<void> createMemberEvent(String uniqueID, Map<String, dynamic> dateTime,
      String type) async {
    try {
      if (type == "members"){
        db.collection("users")
            .doc("members")
            .collection(uniqueID)
            .doc("Event")
            .collection("Pending Appointment")
            .doc().set(dateTime);
      }
      else {
        db.collection("users")
            .doc("admins")
            .collection(uniqueID)
            .doc("Event")
            .collection("Church Event")
            .doc().set(dateTime);
      }
    } catch (e) {
      log("Error code STORAGE: $e");
    }
  }


 Future<List<DateTime>> getPendingDate(String uid) async {
    List<DateTime> documents = [];
     await db.collection("users")
       .doc("members")
       .collection(uid)
       .doc("Event")
       .collection("Pending Appointment")
        .get()
       .then((value) {
          for (var element in value.docs) {
            Timestamp t = element.data()["date"];
            DateTime dats = t.toDate();
            documents.add(dats);
          }
        });
    return documents;
  }

  Future<void> setDisableDay(Map<String,dynamic> dateTime,String uid) async{
      try{
        db.collection("users")
            .doc("admins")
            .collection(uid)
            .doc("Event")
            .collection("Disabled Days")
            .doc()
            .set(dateTime);
      }catch(e){
        log(e.toString());
      }
  }

  Future<List<DateTime>> getDisableDay() async{
      List<DateTime> documents = [];
      try{
        db.collectionGroup("Disabled Days")
            .get()
            .then((value) {
              for(var element in value.docs){
                Timestamp t = element.data()["date"];
                DateTime dats = t.toDate();
                documents.add(dats);
              }
            },);
      }catch(e){
      }
    return documents;
  }

  Stream<QuerySnapshot> fetchPendingAppointments(String uid) {
    return db
        .collection("users")
        .doc("members")
        .collection(uid)
        .doc("Event")
        .collection("Pending Appointment")
        .snapshots();
  }


  Stream<QuerySnapshot> fetchAllPendingAppointments() {
    return db
        .collectionGroup("Pending Appointment")
        .snapshots();
  }

  Stream<QuerySnapshot> fetchApprovedAppointments(String uid) {
    return db
        .collection("users")
        .doc("members")
        .collection(uid)
        .doc("Event")
        .collection("Approved Appointment")
        .snapshots();
  }

  Stream<QuerySnapshot> fetchAllApprovedAppointments() {
    return db
        .collectionGroup("Approved Appointment")
        .snapshots();
  }

  Future<void> approvedAppointment(String userID, String appointmentId) async {
    try {
      DocumentSnapshot appointmentDoc = await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Pending Appointment")
          .doc(appointmentId)
          .get();

      // Update status field to 'Approved'
      await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Pending Appointment")
          .doc(appointmentId)
          .update({'status': 'Approved'});

      // Move appointment to 'Approved Appointment' collection
      await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Approved Appointment")
          .doc(appointmentId) // Use the same appointmentId
          .set(appointmentDoc.data() as Map<String, dynamic>);

      // Delete from 'Pending Appointment' collection
      await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Pending Appointment")
          .doc(appointmentId)
          .delete();

      // Send notification
      await storeNotification(
          'Appointment Approved',
          'Your appointment has been approved.');
    } catch (e) {
      log("Error approving appointment: $e");
    }
  }

  Future<void> denyAppointment(String userID, String appointmentId) async {
    try {
      DocumentSnapshot appointmentDoc = await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Pending Appointment")
          .doc(appointmentId)
          .get();

      // Update status field to 'Denied'
      await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Pending Appointment")
          .doc(appointmentId)
          .update({'status': 'Denied'});

      // Move appointment to 'Denied Appointment' collection
      await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Denied Appointment")
          .doc(appointmentId)
          .set(appointmentDoc.data() as Map<String, dynamic>);

      // Delete from 'Pending Appointment' collection
      await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Pending Appointment")
          .doc(appointmentId)
          .delete();

      // Send notification
      await storeNotification(
          'Appointment Denied',
          'Your appointment has been denied.');
    } catch (e) {
      log("Error denying appointment: $e");
    }
  }


  Stream<QuerySnapshot> fetchDenyAppointment() {
    return db
        .collectionGroup("Denied Appointment")
        .snapshots();
  }


  Stream<QuerySnapshot> fetchCreateMemberEvent(){
    return db
        .collectionGroup("Church Event")
        .snapshots();
  }


}
