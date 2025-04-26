import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailBooking extends StatefulWidget {
  const DetailBooking({super.key});

  @override
  State<DetailBooking> createState() => _DetailBookingState();
}

class _DetailBookingState extends State<DetailBooking> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String selectedStatus = 'All';
  String selectedDateFilter = 'All';
  DateTime? startDate;
  DateTime? endDate;

  Future<List<Map<String, dynamic>>> fetchBookings() async {
    QuerySnapshot snapshot = await _firestore
        .collection('bookings')
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> allBookings = snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    }).toList();

    if (selectedStatus != 'All') {
      allBookings = allBookings
          .where((booking) => booking['Status'] == selectedStatus)
          .toList();
    }

    if (selectedDateFilter == 'Today') {
      DateTime now = DateTime.now();
      allBookings = allBookings.where((booking) {
        DateTime date = booking['timestamp'].toDate();
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }).toList();
    } else if (selectedDateFilter == 'This Week') {
      DateTime now = DateTime.now();
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      allBookings = allBookings.where((booking) {
        DateTime date = booking['timestamp'].toDate();
        return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            date.isBefore(endOfWeek.add(const Duration(days: 1)));
      }).toList();
    } else if (selectedDateFilter == 'Custom Range' &&
        startDate != null &&
        endDate != null) {
      allBookings = allBookings.where((booking) {
        DateTime date = booking['timestamp'].toDate();
        return date.isAfter(startDate!.subtract(const Duration(days: 1))) &&
            date.isBefore(endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    return allBookings;
  }

  Future<void> pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Booking History")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DropdownButton<String>(
                value: selectedStatus,
                onChanged: (newValue) {
                  setState(() {
                    selectedStatus = newValue!;
                  });
                },
                items: ['All', 'check-in', 'check-out', 'Time-out']
                    .map((filter) => DropdownMenuItem(
                          value: filter,
                          child: Text(filter),
                        ))
                    .toList(),
              ),
              DropdownButton<String>(
                value: selectedDateFilter,
                onChanged: (newValue) async {
                  if (newValue == 'Custom Range') {
                    await pickDateRange();
                  }
                  setState(() {
                    selectedDateFilter = newValue!;
                  });
                },
                items: ['All', 'Today', 'This Week', 'Custom Range']
                    .map((filter) => DropdownMenuItem(
                          value: filter,
                          child: Text(filter),
                        ))
                    .toList(),
              ),
            ],
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
                      child: Text("No booking history available."));
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
                                "Date: ${DateFormat('yyyy-MM-dd HH:mm').format(booking['timestamp'].toDate())}"),
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
