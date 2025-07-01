import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailBooking extends StatefulWidget {
  final String userId;
  const DetailBooking({super.key, required this.userId});

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
  String plateSearch = '';

  @override
  void initState() {
    super.initState();
    fetchParkingOptions();
  }

  Future<void> fetchParkingOptions() async {
    try {
      final String ownerId = FirebaseAuth.instance.currentUser?.uid ?? '';

      QuerySnapshot snapshot = await _firestore
          .collection('parking')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      final names = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return data['nameparking'] ?? 'Unknown';
      }).toSet();

      setState(() {
        parkingOptions = ['All', ...names.cast<String>()];
        print("Owner ID: $ownerId");
      });
    } catch (e) {
      print('Error fetching parking options: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchBookings() async {
    final String ownerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    QuerySnapshot snapshot = await _firestore
        .collection('bookings')
        .where('userId', isEqualTo: ownerId)
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> allBookings = snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    }).toList();

    // 🔽 กรองตามสถานะ
    if (selectedStatus != 'All') {
      allBookings = allBookings
          .where((booking) => booking['Status'] == selectedStatus)
          .toList();
    }

    // 🔽 กรองตามชื่อที่จอดรถ
    if (selectedParking != 'All') {
      allBookings = allBookings
          .where((booking) => booking['nameparking'] == selectedParking)
          .toList();
    }
    // 🔽 กรองตามหมายเลขทะเบียน (plate)
    if (plateSearch.isNotEmpty) {
      String lowerPlate = plateSearch.toLowerCase();
      allBookings = allBookings.where((booking) {
        final charplate = (booking['charplate'] ?? '').toString().toLowerCase();
        final numberplate =
            (booking['numberplate'] ?? '').toString().toLowerCase();
        return charplate.contains(lowerPlate) ||
            numberplate.contains(lowerPlate);
      }).toList();
    }

    // 🔽 กรองตามช่วงเวลา
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
        title: const Text(
          "Booking History",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        elevation: 4,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              child: IconButton(
                icon:
                    const Icon(Icons.filter_alt, color: Colors.white, size: 20),
                tooltip: 'Filter',
                onPressed: () async {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => FilterDialog(
                      selectedStatus: selectedStatus,
                      selectedDateFilter: selectedDateFilter,
                      selectedParking: selectedParking,
                      startDate: startDate,
                      endDate: endDate,
                      parkingList: parkingOptions,
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      selectedStatus = result['Status'];
                      selectedParking = result['nameparking'];
                      selectedDateFilter = result['dateFilter'];
                      startDate = result['startDate'];
                      endDate = result['endDate'];
                      plateSearch = result['plate'] ?? '';
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
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
                    final status =
                        (booking['Status'] ?? 'Pending').toLowerCase();
                    final timestamp = booking['timestamp']?.toDate();

                    // Status-based colors
                    Color statusColor;
                    Color backgroundColor;
                    IconData iconData;

                    switch (status) {
                      case 'check-in':
                        statusColor = Colors.green.shade700;
                        backgroundColor = Colors.green.withOpacity(0.15);
                        iconData = Icons.check_circle;
                        break;
                      case 'check-out':
                        statusColor = Colors.red.shade700;
                        backgroundColor = Colors.red.withOpacity(0.15);
                        iconData = Icons.cancel;
                        break;
                      case 'time-out':
                        statusColor = Colors.purpleAccent.shade700;
                        backgroundColor = Colors.purpleAccent.withOpacity(0.15);
                        iconData = Icons.timer_off;
                        break;
                      default: // pending
                        statusColor = Colors.orange.shade700;
                        backgroundColor = Colors.orange.withOpacity(0.15);
                        iconData = Icons.pending;
                        break;
                    }

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
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
                            color: Colors.blue.shade700,
                          ),
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
                              "LicensePlate: ${booking['charplate'] ?? 'Unknown'} ${booking['numberplate'] ?? 'Unknown'}",
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
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Status: ${status[0].toUpperCase()}${status.substring(1)}",
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          iconData,
                          color: statusColor,
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

  late TextEditingController plateController;

  @override
  void initState() {
    super.initState();
    tempSelectedStatus = widget.selectedStatus;
    tempSelectedDateFilter = widget.selectedDateFilter;
    tempSelectedParking = widget.selectedParking;
    tempStartDate = widget.startDate;
    tempEndDate = widget.endDate;
    plateController = TextEditingController();
  }

  @override
  void dispose()  {
    plateController.dispose();
    super.dispose();
  }

  Future<void> pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: tempStartDate != null && tempEndDate != null
          ? DateTimeRange(start: tempStartDate!, end: tempEndDate!)
          : null,
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
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Filter Bookings"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // 🔍 Plate Number Search Field
            TextFormField(
              controller: plateController,
              decoration: const InputDecoration(
                labelText: "Search by Plate",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),

            // 📌 Status Dropdown
            DropdownButtonFormField<String>(
              value: tempSelectedStatus,
              decoration: const InputDecoration(
                labelText: "Select Status",
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (value) {
                setState(() {
                  tempSelectedStatus = value!;
                });
              },
              items: ['All', 'check-in', 'check-out', 'Time-out', 'pending']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child:
                            Text(status[0].toUpperCase() + status.substring(1)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // 📅 Date Filter Dropdown
            DropdownButtonFormField<String>(
              value: tempSelectedDateFilter,
              decoration: const InputDecoration(
                labelText: "Date Filter",
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (value) {
                setState(() {
                  tempSelectedDateFilter = value!;
                  if (tempSelectedDateFilter != 'Custom Range') {
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
            const SizedBox(height: 16),

            // 📆 Custom Date Range Picker
            if (tempSelectedDateFilter == 'Custom Range') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tempStartDate == null
                      ? 'Start: Not set'
                      : 'Start: ${DateFormat('yyyy-MM-dd').format(tempStartDate!)}'),
                  TextButton(
                    onPressed: pickDateRange,
                    child: const Text('Pick Date Range'),
                  ),
                ],
              ),
              if (tempEndDate != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'End: ${DateFormat('yyyy-MM-dd').format(tempEndDate!)}',
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // 🅿️ Parking Dropdown
            DropdownButtonFormField<String>(
              value: tempSelectedParking,
              decoration: const InputDecoration(
                labelText: "Select Parking",
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (value) {
                setState(() {
                  tempSelectedParking = value!;
                });
              },
              items: widget.parkingList
                  .map((parking) => DropdownMenuItem(
                        value: parking,
                        child: Text(parking),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
          ),
          onPressed: () {
            Navigator.of(context).pop({
              'Status': tempSelectedStatus,
              'dateFilter': tempSelectedDateFilter,
              'nameparking': tempSelectedParking,
              'startDate': tempStartDate,
              'endDate': tempEndDate,
              'plate': plateController.text.trim(), // 👈 Return plate text
            });
          },
          child: const Text(
            "Apply Filters",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
