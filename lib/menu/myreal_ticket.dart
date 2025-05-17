import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parking1/menu/real_ticket.dart';

class MyrealTicket extends StatefulWidget {
  final String empId;
  const MyrealTicket({super.key, required this.empId});

  @override
  State<MyrealTicket> createState() => _MyrealTicketState();
}

class _MyrealTicketState extends State<MyrealTicket> {
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text("ປີ້ປັດຈຸບັນ"),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ticketreal')
                .where('Status', isEqualTo: 'check-in')
                .where('empId', isEqualTo: widget.empId)
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

              tickets.sort((a, b) {
                String statusA = a['Status'] ?? 'check-in';
                String statusB = b['Status'] ?? 'check-in';

                if (statusA == 'check-out' || statusA == 'Time-out') return 1;
                if (statusB == 'check-out' || statusB == 'Time-out') return -1;
                return 0;
              });
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

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RealTicket(ticketData: ticket,),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Ticket ID: ${ticket['ticketId'] ?? 'N/A'}",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Province: ${ticket['province'] ?? 'N/A'}"),
                            Text("Plate Type: ${ticket['plateType'] ?? 'N/A'}"),
                            Text("Name Plate: ${ticket['namePlate'] ?? 'N/A'}"),
                            Text("Plate Number: ${ticket['plate'] ?? 'N/A'}"),
                            const SizedBox(height: 8),
                            ticket['imageUrl'] != ''
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(ticket['imageUrl'], height: 150, fit: BoxFit.cover),
                                  )
                                : const SizedBox(),
                            const SizedBox(height: 8),
                            Text("Status: ${ticket['Status'] ?? 'N/A'}"),
                            const SizedBox(height: 4),
                            Text("Date/Time: ${ticket['timestamp'] != null ? ticket['timestamp'].toDate().toString() : 'N/A'}"),
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
