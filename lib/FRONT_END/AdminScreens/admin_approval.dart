import 'dart:developer';
import 'package:bethel_app_final/BACK_END/Services/Functions/Users.dart';
import 'package:bethel_app_final/FRONT_END/MemberScreens/widget_member/sort_icon.dart';
import 'package:bethel_app_final/FRONT_END/constant/color.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminApproval extends StatefulWidget {
  const AdminApproval({Key? key}) : super(key: key);

  @override
  State<AdminApproval> createState() => _AdminApprovalState();
}

class _AdminApprovalState extends State<AdminApproval> {
  late Stream<QuerySnapshot> _pendingAppointmentsStream;
  Map<String, bool> showOptionsMap = {};
  SortingButton sortingButton = SortingButton();
  final UserStorage userStorage = UserStorage();

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  Future<void> _initializeStream() async {
    try {
      _pendingAppointmentsStream = UserStorage().fetchAllPendingAppointments();
    } catch (e) {
      log("Error initializing stream: $e");
    }
  }
  Future<void> approvedAppointment(String userID, String appointmentId) async {
    try {
      await userStorage.approvedAppointment(userID, appointmentId);
    } catch (e) {
      log("Error approving appointment: $e");
    }
  }

  Future<void> denyAppointment(String userID, String appointmentId) async {
    try {
      await userStorage.denyAppointment(userID, appointmentId);
    } catch (e) {
      log("Error denying appointment: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingAppointmentsStream == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.sort),
                ),
                const Text(
                  "Admin Approval",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 50),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(
              color: Colors.green,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _pendingAppointmentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No pending appointment.',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    );
                  }
                  return ListView(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Pending Requests:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ...snapshot.data!.docs.map((DocumentSnapshot document) {
                        final id = document.id;
                        Map<String, dynamic> data =
                        document.data() as Map<String, dynamic>;
                        Timestamp timeStamp = data["date"];
                        DateTime dateTime = timeStamp.toDate();
                        List<String> months = [
                          "January",
                          "February",
                          "March",
                          "April",
                          "May",
                          "June",
                          "July",
                          "August",
                          "September",
                          "October",
                          "November",
                          "December"
                        ];
                        String formattedDate =
                            "${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}";
                        return Card(
                          color: Colors.amber.shade200,
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          child: ListTile(
                            title: Text(
                              'Appointment type: ${data['appointmenttype'] ?? ''}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description: ${data['description'] ?? ''}',
                                ),
                                Text(
                                  'Date: $formattedDate',
                                ),
                                Text(
                                  'name: ${data['name'] ?? ''}',
                                ),
                                Text(
                                  'email: ${data['email'] ?? ''}',
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info),
                                  onPressed: () {
                                    setState(() {
                                      showOptionsMap[id] = !(showOptionsMap[id] ?? false);
                                    });
                                  },
                                ),
                                if (showOptionsMap[id] ?? false)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check,
                                            color: appGreen,
                                            size: 24.0,
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                               return AlertDialog(
                                                  title: const Text("Confirm Approval"),
                                                  content: const Text("Are you sure you want to approve this request?"),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: const Text("Cancel"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        String appointmentId = id; // Get the appointmentId from the document
                                                        String userID = data['userID']; // Get the userID from the document
                                                        if (appointmentId.isNotEmpty && userID.isNotEmpty) {
                                                          approvedAppointment(userID, appointmentId);
                                                          Navigator.of(context).pop(); // Close the dialog
                                                        } else {
                                                          // Handle case where either appointmentId or userID is empty
                                                        }
                                                      },
                                                      child: const Text("Approve", style: TextStyle(color: appGreen)),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),

                                        const SizedBox(width: 8.0),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.close,
                                              color: Colors.red,
                                              size: 24.0
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                               return AlertDialog(
                                                  title: const Text("Confirm Deny"),
                                                  content: const Text("Are you sure you want to deny this request?"),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: const Text("Cancel"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        String appointmentId = id; // Get the appointmentId from the document
                                                        String userID = data['userID']; // Get the userID from the document
                                                        if (appointmentId.isNotEmpty && userID.isNotEmpty) {
                                                          denyAppointment(userID, appointmentId);
                                                          Navigator.of(context).pop(); // Close the dialog
                                                        } else {
                                                          // Handle case where either appointmentId or userID is empty
                                                        }
                                                      },
                                                      child: const Text("Deny", style: TextStyle(color: appRed)),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),

                                      ],
                                    ),
                                  ),
                              ],
                            ),

                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
