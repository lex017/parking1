import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailEmployee extends StatefulWidget {
  const DetailEmployee({super.key});

  @override
  State<DetailEmployee> createState() => _DetailEmployeeState();
}

class _DetailEmployeeState extends State<DetailEmployee> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String selectedFilter = 'All';

  Future<List<Map<String, dynamic>>> fetchBookings() async {
    QuerySnapshot snapshot = await _firestore
        .collection('bookings')
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> allBookings = snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    }).toList();

    // Get today's date without time
    DateTime today = DateTime.now();
    String todayString = DateFormat('yyyy-MM-dd').format(today);

    List<Map<String, dynamic>> filteredBookings = allBookings.where((booking) {
      DateTime? checkInTime = booking['checkInTime']?.toDate();
      DateTime? checkOutTime = booking['checkOutTime']?.toDate();

      bool isTodayCheckIn = checkInTime != null &&
          DateFormat('yyyy-MM-dd').format(checkInTime) == todayString;

      bool isTodayCheckOut = checkOutTime != null &&
          DateFormat('yyyy-MM-dd').format(checkOutTime) == todayString;

      if (selectedFilter == 'Check-in') {
        return isTodayCheckIn;
      } else if (selectedFilter == 'Check-out') {
        return isTodayCheckOut;
      } else if (selectedFilter == 'Timeout') {
        return booking['timeout'] != null;
      }
      return isTodayCheckIn || isTodayCheckOut; // Show today's check-ins and check-outs
    }).toList();

    return filteredBookings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Scan History")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                DropdownButton<String>(
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
              ],
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
                  return const Center(
                      child: Text("No booking history available for today."));
                }

                List<Map<String, dynamic>> bookings = snapshot.data!;
                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> booking = bookings[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(booking['userName'] ?? 'Unknown User',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Parking: ${booking['nameparking'] ?? 'Unknown'}"),
                            Text(
                                "Check-in: ${booking['checkInTime'] != null ? DateFormat('hh:mm a').format(booking['checkInTime'].toDate()) : 'N/A'}"),
                            Text(
                                "Check-out: ${booking['checkOutTime'] != null ? DateFormat('hh:mm a').format(booking['checkOutTime'].toDate()) : 'N/A'}"),
                            Text("Status: ${booking['Status'] ?? 'Pending'}"),
                          ],
                        ),
                        trailing: Icon(
                          booking['Status'] == 'Completed'
                              ? Icons.check_circle
                              : Icons.pending,
                          color: booking['Status'] == 'Completed'
                              ? Colors.green
                              : Colors.orange,
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
