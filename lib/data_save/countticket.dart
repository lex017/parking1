import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TicketCountPage extends StatefulWidget {
  @override
  _TicketCountPageState createState() => _TicketCountPageState();
}

class _TicketCountPageState extends State<TicketCountPage> {
  Future<int> countCheckedInTickets() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID

      QuerySnapshot ticketSnapshot = await FirebaseFirestore.instance
          .collection('bookings') // Firestore collection name
          .where('userId', isEqualTo: userId) // Filter for current user
          .where('parkingStatus', isEqualTo: 'check-in') // Filter only "check-in" status
          .get();

      return ticketSnapshot.docs.length; // Return count of matching documents
    } catch (e) {
      print("Error fetching tickets: $e");
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Checked-in Tickets'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Center(
        child: FutureBuilder<int>(
          future: countCheckedInTickets(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(); // Show loading indicator
            }
            if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            }
            return Text(
              "Checked-in Tickets: ${snapshot.data}",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
    );
  }
}
