import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:parking1/menu/emp_verify.dart';

class EmpNotification extends StatefulWidget {
  final String empId;
  final String locationId;

  const EmpNotification({
    super.key,
    required this.empId,
    required this.locationId,
  });

  @override
  State<EmpNotification> createState() => _EmpNotificationState();
}

class _EmpNotificationState extends State<EmpNotification> {
  String locationId = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEmployeeLocationId();
    _initializeNotifications();
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> fetchEmployeeLocationId() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('employees')
          .doc(widget.empId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('locationId')) {
          setState(() {
            locationId = data['locationId'];
            isLoading = false;
          });
          print('Loaded Location ID: $locationId');
        } else {
          setState(() => isLoading = false);
          print('locationId not found in employee data.');
        }
      } else {
        setState(() => isLoading = false);
        print('Employee document not found.');
      }
    } catch (e) {
      print('Error fetching employee locationId: $e');
      setState(() => isLoading = false);
    }
  }

 

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting ||
            isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("My Tickets")),
            body:
                const Center(child: Text("pleace login for see your ticket")),
          );
        }

        if (locationId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("dont see a locationid")),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text("Pending Tickets"),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('payments')
                .where('locationId', isEqualTo: locationId)
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                    child: Text("Error to loading data"));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Dont have list to working"));
              }

              final documents = snapshot.data!.docs;

             

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  var doc = documents[index];
                  var ticket = doc.data() as Map<String, dynamic>;
                  var paymentId = doc.id;

                  String paymentDate = ticket['date'] ?? 'N/A';
                  String paymentName = ticket['userName'] ?? 'N/A';
                  String paymentTime = ticket['time'] ?? 'N/A';
                  String status = ticket['status'] ?? 'N/A';
                  String? imageUrl = ticket['imageUrl'];
                  bool isCheckOut = status == 'check-out';

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: isCheckOut ? Colors.grey[300] : Colors.white,
                    child: InkWell(
                      onTap: isCheckOut
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EmpVerify(
                                    paymentId: paymentId,
                                    locationId: locationId,
                                  ),
                                ),
                              );
                            },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCheckOut
                                    ? Colors.grey
                                    : Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                'assets/images/history.png',
                                width: 28,
                                height: 28,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Name: $paymentName",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isCheckOut
                                          ? Colors.grey[700]
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Date: $paymentDate | Time: $paymentTime",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isCheckOut
                                          ? Colors.grey[600]
                                          : Colors.black54,
                                    ),
                                  ),
                                  if (imageUrl != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCheckOut
                                    ? Colors.grey[700]
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
