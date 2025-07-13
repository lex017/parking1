import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parking1/data_save/buyticket.dart';
import 'package:parking1/menu/real_ticket.dart';

class DetailEmployee extends StatefulWidget {
  final String empId;
  final String locationId;
  const DetailEmployee({super.key, required this.empId, required this.locationId});

  @override
  State<DetailEmployee> createState() => _DetailEmployeeState();
}

class _DetailEmployeeState extends State<DetailEmployee> {
  final _firestore = FirebaseFirestore.instance;
  String selectedStatus = 'All';
  String selectedDateFilter = 'All Day';
  String selectedPaymentMethod = 'All';
  DateTime? startDate, endDate;

  Future<List<Map<String, dynamic>>> fetchBookings() async {
    // fetch & combine
    final ticketreal = await _firestore
        .collection('ticketreal')
        .where('empId', isEqualTo: widget.empId)
        .get();
    final bookingsSnap = await _firestore
        .collection('bookings')
        .where('locationId', isEqualTo: widget.locationId)
        .get();

    var all = [
      ...ticketreal.docs.map((d) => {...d.data(), 'id': d.id, 'source': 'ticketreal'}),
      ...bookingsSnap.docs.map((d) => {...d.data(), 'id': d.id, 'source': 'bookings'}),
    ].cast<Map<String, dynamic>>();

    // status filter
    if (selectedStatus != 'All') {
      all = all.where((b) => b['Status'] == selectedStatus).toList();
    }

    // date filter
    final now = DateTime.now();
    if (selectedDateFilter == 'Today') {
      all = all.where((b) {
        final d = (b['timestamp'] as Timestamp).toDate();
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).toList();
    } else if (selectedDateFilter == 'This Week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      all = all.where((b) {
        final d = (b['timestamp'] as Timestamp).toDate();
        return d.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
               d.isBefore(endOfWeek.add(const Duration(days: 1)));
      }).toList();
    } else if (selectedDateFilter == 'Custom Range' && startDate != null && endDate != null) {
      all = all.where((b) {
        final d = (b['timestamp'] as Timestamp).toDate();
        return d.isAfter(startDate!.subtract(const Duration(days: 1))) &&
               d.isBefore(endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // paymentMethod filter
    if (selectedPaymentMethod != 'All') {
      all = all.where((b) {
        final method = (b['paymentMethod'] ?? '').toString().toLowerCase();
        if (method.isEmpty) return true;
        if (selectedPaymentMethod == 'booking') {
          return method != 'cash' && method != 'transfer';
        }
        return method == selectedPaymentMethod.toLowerCase();
      }).toList();
    }

    // sort
    all.sort((a, b) =>
        (b['timestamp'] as Timestamp).toDate().compareTo((a['timestamp'] as Timestamp).toDate()));

    return all;
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() {
      startDate = picked.start;
      endDate = picked.end;
    });
  }

  void showFilterSheet() {
    String tempStatus = selectedStatus;
    String tempDate = selectedDateFilter;
    String tempPay   = selectedPaymentMethod;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (c, setM) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              _buildChoiceRow('Status', ['All','check-in','check-out'], tempStatus, (v){
                setM(()=>tempStatus=v);
              }),
              const SizedBox(height: 12),

              _buildChoiceRow('Date', ['All Day','Today','This Week','Custom Range'], tempDate, (v) async {
                if (v=='Custom Range') await pickDateRange();
                setM(()=>tempDate=v);
              }),
              const SizedBox(height: 12),

              _buildChoiceRow('Payment', ['All','cash','transfer','booking'], tempPay, (v){
                setM(()=>tempPay=v);
              }),
              const SizedBox(height: 20),

             ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blueAccent,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(50),
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(vertical: 14),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),
  onPressed: () {
    setState(() {
      selectedStatus = tempStatus;
      selectedDateFilter = tempDate;
      selectedPaymentMethod = tempPay;
    });
    Navigator.pop(ctx);
  },
  child: const Text('Apply Filters'),
),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceRow(String label, List<String> options, String selected, ValueChanged<String> onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: options.map((o) => ChoiceChip(
            label: Text(o),
            selected: selected==o,
            onSelected: (_) => onTap(o),
            selectedColor: Colors.blue.shade100,
            backgroundColor: Colors.grey.shade200,
          )).toList(),
        )
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: showFilterSheet,
          )
        ],
      ),
      body: Column(
        children: [
          // Active filters summary
          if (selectedStatus!='All' || selectedDateFilter!='All Day' || selectedPaymentMethod!='All')
            Container(
              color: Colors.blue.shade50,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (selectedStatus!='All') Chip(label: Text('Status: $selectedStatus')),
                  if (selectedDateFilter!='All Day') Chip(label: Text('Date: $selectedDateFilter')),
                  if (selectedPaymentMethod!='All') Chip(label: Text('Payment: $selectedPaymentMethod')),
                ],
              ),
            ),
          
          Expanded(
  child: FutureBuilder<List<Map<String, dynamic>>>(
    future: fetchBookings(),
    builder: (ctx, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snap.hasError) {
        return Center(child: Text('Error: ${snap.error}'));
      }
      final list = snap.data!;
      if (list.isEmpty) {
        return const Center(child: Text('No bookings found.'));
      }

      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final booking = list[index];
          final timestamp = (booking['timestamp'] as Timestamp).toDate();
          final status = (booking['Status'] ?? 'Pending').toLowerCase();

          IconData statusIcon;
          Color statusColor;

          switch (status) {
            case 'check-in':
              statusIcon = Icons.login;
              statusColor = Colors.green;
              break;
            case 'check-out':
              statusIcon = Icons.logout;
              statusColor = Colors.red;
              break;
            default:
              statusIcon = Icons.pending;
              statusColor = Colors.orange;
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onTap: () {
                if (booking['source'] == 'ticketreal') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RealTicket(ticketData: booking),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BuyTicket(bookingId: booking['id']),
                    ),
                  );
                }
              },
            
              title: Text(
                booking['source'] == 'ticketreal'
                    ? (booking['empId'] ?? 'Unknown')
                    : (booking['userName'] ?? 'Unknown User'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text("Parking: ${booking['locationId'] ?? 'Unknown'}"),
                  Text("Date: ${DateFormat('yyyy-MM-dd HH:mm').format(timestamp)}"),
                  Text("Status: ${status[0].toUpperCase()}${status.substring(1)}"),
                  Text("Payment Method: ${booking['paymentMethod'] ?? 'Booking'}"),
                ],
              ),
              trailing: Icon(statusIcon, color: statusColor),
            ),
          );
        },
      );
    },
  ),
)

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