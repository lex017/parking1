import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parking1/data_save/buyticket.dart';

class MyTicket extends StatefulWidget {
  const MyTicket({super.key});

  @override
  State<MyTicket> createState() => _MyTicketState();
}

class _MyTicketState extends State<MyTicket> {
  final user = FirebaseAuth.instance.currentUser;

  Future<String> getUserName(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc['username'] ?? 'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      print("Error fetching userName: $e");
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("My Tickets")),
            body:
                const Center(child: Text("Please log in to view your tickets")),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text('myticket'.tr()),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('userId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                    child: Text("There was an error loading tickets"));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("NO tickets available"));
              }

              var tickets = snapshot.data!.docs.toList();

// 🔴 Filter out tickets with status 'Time-out'
              tickets = tickets.where((doc) {
                final status = doc['Status'] ?? '';
                return status != 'Time-out';
              }).toList();
              // 🔴 Filter out tickets with status 'Time-out'
              tickets = tickets.where((doc) {
                final status = doc['paymentStatus'] ?? '';
                return status != 'reject';
              }).toList();

// Sort by timestamp descending
              tickets.sort((a, b) {
                Timestamp timeA = a['timestamp'] ?? Timestamp(0, 0);
                Timestamp timeB = b['timestamp'] ?? Timestamp(0, 0);
                return timeB.compareTo(timeA);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  var ticket = tickets[index].data() as Map<String, dynamic>;

                  String bookingId = tickets[index].id;
                  String bookingDate = ticket['bookingDate'] ?? 'N/A';
                  String bookingname = ticket['nameparking'] ?? 'N/A';
                  String bookingTime = ticket['bookingTime'] ?? 'N/A';
                  String status = ticket['Status'] ?? 'N/A';
                  String paymentStatus = ticket['paymentStatus'] ?? 'pending';
                  bool isClickable = paymentStatus == 'success';

                  return FutureBuilder<String>(
                    future: getUserName(user.uid),
                    builder: (context, userNameSnapshot) {
                      if (userNameSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return Opacity(
                        opacity: isClickable ? 1.0 : 0.5,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          child: InkWell(
                            onTap: isClickable
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BuyTicket(bookingId: bookingId),
                                      ),
                                    );
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Location: $bookingname",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Date: $bookingDate | Time: $bookingTime",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        if (!isClickable)
                                          const Text(
                                            "Waiting for payment confirmation...",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    status,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
