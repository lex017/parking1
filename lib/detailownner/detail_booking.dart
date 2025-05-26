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
  String selectedParking = 'All';
  DateTime? startDate;
  DateTime? endDate;
  List<String> parkingOptions = ['All'];

@override
  void initState() {
    super.initState();
    fetchParkingOptions();
  }

  Future<void> fetchParkingOptions() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('bookings').get();
      final names = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return data['nameparking'] ?? 'Unknown';
      }).toSet();

      setState(() {
        parkingOptions = ['All', ...names.cast<String>()];
      });
    } catch (e) {
      print('Error: $e');
    }
  }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking History"),
        backgroundColor: Colors.blue,
        elevation: 4,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
              icon: const Icon(Icons.filter_alt, size: 20),
              label: const Text(
                "Filter Bookings",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,color: Colors.white),
              ),
              onPressed: () async {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => FilterDialog(
                    selectedStatus: selectedStatus,
                    selectedDateFilter: selectedDateFilter,
                    startDate: startDate,
                    endDate: endDate, selectedParking: selectedParking, parkingList: [],
                  ),
                );

                if (result != null) {
                  setState(() {
                    selectedStatus = result['status'];
                    selectedParking = result['nameparking'];
                    selectedDateFilter = result['dateFilter'];
                    startDate = result['startDate'];
                    endDate = result['endDate'];
                  });
                }
              },
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
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "No booking history available.",
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  );
                }

                List<Map<String, dynamic>> bookings = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> booking = bookings[index];
                    final status = booking['Status'] ?? 'Pending';
                    final bool isCompleted = status.toLowerCase() == 'completed';
                    final timestamp = booking['timestamp']?.toDate();

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 6,
                      shadowColor: Colors.deepPurpleAccent.withOpacity(0.3),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        title: Text(
                          booking['userName'] ?? 'Unknown User',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              "Parking: ${booking['nameparking'] ?? 'Unknown'}",
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timestamp != null
                                  ? "Date: ${DateFormat('yyyy-MM-dd HH:mm').format(timestamp)}"
                                  : "Date: Unknown",
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? Colors.green.withOpacity(0.15)
                                    : Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Status: $status",
                                style: TextStyle(
                                  color: isCompleted
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          isCompleted ? Icons.check_circle : Icons.pending,
                          color: isCompleted ? Colors.green : Colors.orange,
                          size: 30,
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

class FilterDialog extends StatefulWidget {
  final String selectedStatus;
  final String selectedDateFilter;
  final String selectedParking;
  final List<String> parkingList;
  final DateTime? startDate;
  final DateTime? endDate;

  const FilterDialog({
    super.key,
    required this.selectedStatus,
    required this.selectedDateFilter,
    required this.selectedParking,
    required this.parkingList,
    this.startDate,
    this.endDate,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late String tempSelectedStatus;
  late String tempSelectedDateFilter;
  late String tempSelectedParking;
  DateTime? tempStartDate;
  DateTime? tempEndDate;

  @override
  void initState() {
    super.initState();
    tempSelectedStatus = widget.selectedStatus;
    tempSelectedDateFilter = widget.selectedDateFilter;
    tempSelectedParking = widget.selectedParking;
    tempStartDate = widget.startDate;
    tempEndDate = widget.endDate;
  }

  Future<void> pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: tempStartDate != null && tempEndDate != null
          ? DateTimeRange(start: tempStartDate!, end: tempEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.blue,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        tempStartDate = picked.start;
        tempEndDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Filter Bookings",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: tempSelectedStatus,
              decoration: const InputDecoration(
                labelText: "Select Status",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (value) {
                setState(() {
                  tempSelectedStatus = value!;
                });
              },
              items: ['All', 'check-in', 'check-out', 'Time-out']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status[0].toUpperCase() + status.substring(1),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),

            // 🅿️ Parking Filter
            DropdownButtonFormField<String>(
              value: tempSelectedParking,
              decoration: const InputDecoration(
                labelText: "Select Parking",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (value) {
                setState(() {
                  tempSelectedParking = value!;
                });
              },
              items: ['All', ...widget.parkingList]
                  .map((parking) => DropdownMenuItem(
                        value: parking,
                        child: Text(parking),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: tempSelectedDateFilter,
              decoration: const InputDecoration(
                labelText: "Select Date Filter",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (value) async {
                if (value == 'Custom Range') {
                  await pickDateRange();
                }
                setState(() {
                  tempSelectedDateFilter = value!;
                  if (value != 'Custom Range') {
                    tempStartDate = null;
                    tempEndDate = null;
                  }
                });
              },
              items: ['All', 'Today', 'This Week', 'Custom Range']
                  .map((filter) => DropdownMenuItem(
                        value: filter,
                        child: Text(filter),
                      ))
                  .toList(),
            ),
            if (tempSelectedDateFilter == 'Custom Range' &&
                tempStartDate != null &&
                tempEndDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    "From: ${DateFormat('yyyy-MM-dd').format(tempStartDate!)}\nTo: ${DateFormat('yyyy-MM-dd').format(tempEndDate!)}",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.only(right: 12, bottom: 12),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.pop(context, {
              'status': tempSelectedStatus,
              'dateFilter': tempSelectedDateFilter,
              'parking': tempSelectedParking,
              'startDate': tempStartDate,
              'endDate': tempEndDate,
            });
          },
          child: const Text("Apply"),
        ),
      ],
    );
  }
}