import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailEmployee extends StatefulWidget {
  final String empId;
  const DetailEmployee({super.key, required this.empId});

  @override
  State<DetailEmployee> createState() => _DetailEmployeeState();
}

class _DetailEmployeeState extends State<DetailEmployee> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String selectedStatus = 'All';
  String selectedDateFilter = 'All Day';
  DateTime? startDate;
  DateTime? endDate;

  Future<List<Map<String, dynamic>>> fetchBookings() async {
    QuerySnapshot snapshot = await _firestore
        .collection('ticketreal')
        .where('empId', isEqualTo: widget.empId)
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

  void showCombinedFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        String tempStatus = selectedStatus;
        String tempDateFilter = selectedDateFilter;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Select Filters",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Status Filter
                  const Align(
                      alignment: Alignment.centerLeft, child: Text("Status")),
                  Wrap(
                    spacing: 10,
                    children: ['All', 'check-in', 'check-out'].map((status) {
                      return ChoiceChip(
                        label: Text(status),
                        selected: tempStatus == status,
                        onSelected: (selected) {
                          setModalState(() {
                            tempStatus = status;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Date Filter
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Date Filter")),
                  Wrap(
                    spacing: 10,
                    children: ['All Day', 'Today', 'This Week', 'Custom Range']
                        .map((filter) {
                      return ChoiceChip(
                        label: Text(filter),
                        selected: tempDateFilter == filter,
                        onSelected: (selected) async {
                          if (filter == 'Custom Range') {
                            await pickDateRange();
                          }
                          setModalState(() {
                            tempDateFilter = filter;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue
                    ),
                    onPressed: () {
                      setState(() {
                        selectedStatus = tempStatus;
                        selectedDateFilter = tempDateFilter;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Apply Filters",style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Booking History",

        ),

        elevation: 4,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              child: IconButton(
                onPressed: () => showCombinedFilterSheet(context),
                icon: const Icon(Icons.filter_alt_rounded, color: Colors.black),
                padding: const EdgeInsets.all(12),
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
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("No booking history available."));
                }

                List<Map<String, dynamic>> ticketreal = snapshot.data!;
                return ListView.builder(
                  itemCount: ticketreal.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> booking = ticketreal[index];

                    IconData statusIcon;
                    Color statusColor;

                    switch (booking['Status']) {
                      case 'check-in':
                        statusIcon = Icons.check_circle;
                        statusColor = Colors.green;
                        break;
                      case 'check-out':
                        statusIcon = Icons.cancel;
                        statusColor = Colors.red;
                        break;
                      default:
                        statusIcon = Icons.pending;
                        statusColor = Colors.orange;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          booking['empId'] ?? 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Parking: ${booking['locationId'] ?? 'Unknown'}"),
                            Text(
                                "Date: ${DateFormat('yyyy-MM-dd HH:mm').format(booking['timestamp'].toDate())}"),
                            Text("Status: ${booking['Status'] ?? 'Pending'}"),
                          ],
                        ),
                        trailing: Icon(statusIcon, color: statusColor),
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




// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class DetailEmployee extends StatefulWidget {
//   final String empId;
//   const DetailEmployee({super.key, required this.empId});

//   @override
//   State<DetailEmployee> createState() => _DetailBookingState();
// }

// class _DetailBookingState extends State<DetailEmployee> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   String selectedStatus = 'All';
//   String selectedDateFilter = 'All Day';
//   DateTime? startDate;
//   DateTime? endDate;

//   Future<List<Map<String, dynamic>>> fetchBookings() async {
//     QuerySnapshot snapshot = await _firestore
//         .collection('ticketreal')
//         .where('empId', isEqualTo: widget.empId) // <-- filter here

//         .get();

//     List<Map<String, dynamic>> allBookings = snapshot.docs.map((doc) {
//       return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
//     }).toList();

//     if (selectedStatus != 'All') {
//       allBookings = allBookings
//           .where((booking) => booking['Status'] == selectedStatus)
//           .toList();
//     }

//     if (selectedDateFilter == 'Today') {
//       DateTime now = DateTime.now();
//       allBookings = allBookings.where((booking) {
//         DateTime date = booking['timestamp'].toDate();
//         return date.year == now.year &&
//             date.month == now.month &&
//             date.day == now.day;
//       }).toList();
//     } else if (selectedDateFilter == 'This Week') {
//       DateTime now = DateTime.now();
//       DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
//       DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
//       allBookings = allBookings.where((booking) {
//         DateTime date = booking['timestamp'].toDate();
//         return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
//             date.isBefore(endOfWeek.add(const Duration(days: 1)));
//       }).toList();
//     } else if (selectedDateFilter == 'Custom Range' &&
//         startDate != null &&
//         endDate != null) {
//       allBookings = allBookings.where((booking) {
//         DateTime date = booking['timestamp'].toDate();
//         return date.isAfter(startDate!.subtract(const Duration(days: 1))) &&
//             date.isBefore(endDate!.add(const Duration(days: 1)));
//       }).toList();
//     }

//     return allBookings;
//   }

//   Future<void> pickDateRange() async {
//     DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2100),
//     );

//     if (picked != null) {
//       setState(() {
//         startDate = picked.start;
//         endDate = picked.end;
//       });
//     }
//   }
// void showStatusFilterSheet(BuildContext context) {
//   showModalBottomSheet(
//     context: context,
//     builder: (context) {
//       return ListView(
//         shrinkWrap: true,
//         children: ['All', 'check-in', 'check-out'].map((status) {
//           return ListTile(
//             title: Text(status),
//             onTap: () {
//               setState(() {
//                 selectedStatus = status;
//               });
//               Navigator.pop(context);
//             },
//           );
//         }).toList(),
//       );
//     },
//   );
// }

// void showDateFilterSheet(BuildContext context) {
//   showModalBottomSheet(
//     context: context,
//     builder: (context) {
//       return ListView(
//         shrinkWrap: true,
//         children: ['All Day', 'Today', 'This Week', 'Custom Range'].map((filter) {
//           return ListTile(
//             title: Text(filter),
//             onTap: () async {
//               if (filter == 'Custom Range') {
//                 await pickDateRange();
//               }
//               setState(() {
//                 selectedDateFilter = filter;
//               });
//               Navigator.pop(context);
//             },
//           );
//         }).toList(),
//       );
//     },
//   );
// }

//  @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(title: const Text("Booking History")),
//     body: Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               // Status Button
//               ElevatedButton.icon(
//                 onPressed: () => showStatusFilterSheet(context),
//                 icon: const Icon(Icons.filter_alt),
//                 label: Text("Status: $selectedStatus"),
//               ),
//               // Date Filter Button
//               ElevatedButton.icon(
//                 onPressed: () => showDateFilterSheet(context),
//                 icon: const Icon(Icons.date_range),
//                 label: Text("Date: $selectedDateFilter"),
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: FutureBuilder<List<Map<String, dynamic>>>(
//             future: fetchBookings(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//               if (snapshot.hasError) {
//                 return Center(child: Text("Error: ${snapshot.error}"));
//               }
//               if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                 return const Center(child: Text("No booking history available."));
//               }

//               List<Map<String, dynamic>> ticketreal = snapshot.data!;
//               return ListView.builder(
//                 itemCount: ticketreal.length,
//                 itemBuilder: (context, index) {
//                   Map<String, dynamic> booking = ticketreal[index];

//                   IconData statusIcon;
//                   Color statusColor;
//                   switch (booking['Status']) {
//                     case 'check-in':
//                       statusIcon = Icons.check_circle;
//                       statusColor = Colors.green;
//                       break;
//                     case 'check-out':
//                       statusIcon = Icons.cancel;
//                       statusColor = Colors.red;
//                       break;
//                     default:
//                       statusIcon = Icons.pending;
//                       statusColor = Colors.orange;
//                   }

//                   return Card(
//                     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     child: ListTile(
//                       title: Text(
//                         booking['empId'] ?? 'Unknown User',
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Parking: ${booking['locationId'] ?? 'Unknown'}"),
//                           Text(
//                             "Date: ${DateFormat('yyyy-MM-dd HH:mm').format(booking['timestamp'].toDate())}",
//                           ),
//                           Text("Status: ${booking['Status'] ?? 'Pending'}"),
//                         ],
//                       ),
//                       trailing: Icon(statusIcon, color: statusColor),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     ),
//   );
// }
// }