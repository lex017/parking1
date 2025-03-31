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

  // Function to fetch the userName from the users collection
  Future<String> getUserName(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc['username'] ?? 'Unknown'; // Return userName or 'Unknown'
      }
      return 'Unknown'; // In case the document doesn't exist
    } catch (e) {
      print("Error fetching userName: $e");
      return 'Unknown'; // Return 'Unknown' in case of error
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
            body: const Center(child: Text("กรุณาเข้าสู่ระบบเพื่อดูตั๋วของคุณ")),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text("My Tickets"),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('paymentStatus', isEqualTo: 'success')
                .where('userId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text("เกิดข้อผิดพลาดในการโหลดตั๋ว"));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("NO tickets available"));
              }

              var tickets = snapshot.data!.docs;

              // Sorting the tickets so that check-out or time-out tickets are at the bottom
              tickets.sort((a, b) {
                String statusA = a['Status'] ?? 'check-in';
                String statusB = b['Status'] ?? 'check-in';

                if (statusA == 'check-out' || statusA == 'time-out') return 1; // Move to bottom
                if (statusB == 'check-out' || statusB == 'time-out') return -1; // Move to bottom
                return 0; // Keep other tickets as they are
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
                  GeoPoint location = ticket['location'] ?? GeoPoint(0.0, 0.0);
                  String parkingStatus = ticket['Status'] ?? 'check-in';
                  bool isCheckOut = parkingStatus == 'check-out';

                  return FutureBuilder<String>(
                    future: getUserName(user.uid), // Fetch username from Firestore
                    builder: (context, userNameSnapshot) {
                      if (userNameSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      String username = userNameSnapshot.data ?? 'Unknown';
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        color: isCheckOut ? Colors.grey[300] : Colors.white,
                        child: InkWell(
                          onTap: isCheckOut
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BuyTicket(bookingId: bookingId),
                                    ),
                                  );
                                },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isCheckOut ? Colors.grey : Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.calendar_view_day_sharp,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Location: $bookingname", // Use the fetched username
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isCheckOut ? Colors.grey[700] : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Date: $bookingDate | Time: $bookingTime",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isCheckOut ? Colors.grey[600] : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "$status",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCheckOut ? Colors.grey[700] : Colors.black,
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
              );
            },
          ),
        );
      },
    );
  }
}
