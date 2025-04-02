import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DetailBooking extends StatefulWidget {
  const DetailBooking({super.key});

  @override
  State<DetailBooking> createState() => _DetailBookingState();
}

class _DetailBookingState extends State<DetailBooking> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String selectedFilter = 'All';

  Future<List<Map<String, dynamic>>> fetchBookings() async {
    QuerySnapshot snapshot = await _firestore.collection('bookings')
        .orderBy('timestamp', descending: true)
        .get();
    
    List<Map<String, dynamic>> allBookings = snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    }).toList();
    
    if (selectedFilter == 'Check-in') {
      return allBookings.where((booking) => booking['checkInTime'] != null).toList();
    } else if (selectedFilter == 'Check-out') {
      return allBookings.where((booking) => booking['checkOutTime'] != null).toList();
    } else if (selectedFilter == 'Timeout') {
      return allBookings.where((booking) => booking['timeout'] != null).toList();
    }
    return allBookings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Booking History")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedFilter,
              onChanged: (newValue) {
                setState(() {
                  selectedFilter = newValue!;
                });
              },
              items: ['All', 'Check-in', 'Check-out', 'Timeout']
                  .map((filter) => DropdownMenuItem(
                        value: filter,
                        child: Text(filter),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No booking history available."));
                }
                
                List<Map<String, dynamic>> bookings = snapshot.data!;
                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> booking = bookings[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(booking['userName'] ?? 'Unknown User',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Parking: ${booking['nameparking'] ?? 'Unknown'}"),
                            Text("Date: ${booking['timestamp']?.toDate().toString() ?? 'N/A'}"),
                            Text("Status: ${booking['Status'] ?? 'Pending'}"),
                          ],
                        ),
                        trailing: Icon(
                          booking['Status'] == 'Completed' ? Icons.check_circle : Icons.pending,
                          color: booking['Status'] == 'Completed' ? Colors.green : Colors.orange,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}