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
          appBar: AppBar(
            title: const Text("My Tickets"),
            backgroundColor: Colors.lightBlue,
          ),
          body: StreamBuilder<QuerySnapshot>(
            // IMPORTANT: Make sure your Firestore documents include a "userId" field.
            // If not, remove the .where('userId', isEqualTo: user.uid) filter for debugging.
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('paymentStatus', isEqualTo: 'success')
                .where('userId', isEqualTo: user.uid) // Ensure "userId" exists in Firestore!
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("เกิดข้อผิดพลาดในการโหลดตั๋ว"));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("คุณไม่มีตั๋วที่ใช้งานอยู่"));
              }
              
              // Debug print to see how many tickets are fetched
              print("Fetched ${snapshot.data!.docs.length} tickets");
              
              var tickets = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  var ticket = tickets[index].data() as Map<String, dynamic>;
                  // Debug print for each ticket document
                  print("Ticket $index data: $ticket");
                  
                  String bookingId = tickets[index].id;
                  String userName = ticket['userName'] ?? 'Unknown';
                  String bookingDate = ticket['bookingDate'] ?? 'N/A';
                  String bookingTime = ticket['bookingTime'] ?? 'N/A';
                  String status = ticket['parkingStatus'] ?? 'N/A';
                  
                  // Get GeoPoint from Firestore properly
                  GeoPoint location = ticket['location'] ?? GeoPoint(0.0, 0.0);
                  String parkingStatus = ticket['parkingStatus'] ?? 'check-in';
                  bool isCheckOut = parkingStatus == 'check-out';
                  
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
                        decoration: !isCheckOut
                            ? BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.lightBlue.shade50],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              )
                            : null,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCheckOut ? Colors.grey : Colors.lightBlue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.local_parking,
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
                                    "User: $userName",
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
          ),
        );
      },
    );
  }
}
