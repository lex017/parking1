import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parking1/menu/emp_detailpend.dart';

class EmpPending extends StatefulWidget {
  final String empId;
  final String locationId;
  const EmpPending({super.key, required this.empId, required this.locationId});

  @override
  State<EmpPending> createState() => _MyrealTicketState();
}

class _MyrealTicketState extends State<EmpPending> {
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
            appBar: AppBar(title: const Text("My Tickets pending")),
            body:
                const Center(child: Text("Your ticket")),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text("Penging"),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('Status', isEqualTo: 'pending')
                .where('locationId', isEqualTo: widget.locationId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text("Loading alert"));
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
                  final vehicleId = ticket["vehicleId"];
                  final bookingId = tickets[index].id;


                  

                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  EmpDetailpend(ticketData: ticket, vehicleId: vehicleId, locationId: widget.locationId, bookingId: bookingId,),
                            ),
                          );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("User: ${ticket['userName'] ?? 'N/A'}"),
                            Text("Vehicle: ${ticket['vehicle'] ?? 'N/A'}"),
                            Text("Status: ${ticket['Status'] ?? 'N/A'}"),
                            Text(
                                "Date/Time: ${ticket['timestamp']?.toDate().toString() ?? 'N/A'}"),
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
