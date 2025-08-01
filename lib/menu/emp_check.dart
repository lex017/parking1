import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ScanCheck extends StatefulWidget {
  final String bookingId;
  final String status;

  const ScanCheck({Key? key, required this.bookingId, required this.status})
      : super(key: key);

  @override
  State<ScanCheck> createState() => _ScanCheckState();
}

class _ScanCheckState extends State<ScanCheck> {
  String status = 'loading';
  String? collectionType;
  DateTime? checkOutTime;
  String? nameParking;
  String? plateNumber;
  String? plateType;
  String? charplate;
  String? province;
  String? plate;
  String? vehicleId;
  String? userName;

  final Map<String, Map<String, Color>> plateColors = {
    "ລັດບໍລິຫານ": {
      "background": Colors.blue,
      "text": Colors.white,
      "border": Colors.white,
    },
    "ເອກະຊົນລາວ": {
      "background": Colors.yellow,
      "text": Colors.black,
      "border": Colors.black,
    },
    "ບໍລິສັດ/ທຸລະກິດ 100%": {
      "background": Colors.white,
      "text": Colors.black,
      "border": Colors.black,
    },
    "ບໍລິສັດ/ທຸລະກິດ 1%": {
      "background": Colors.white,
      "text": Colors.blue,
      "border": Colors.blue,
    },
    "ເອກະຊົນຕ່າງດ້າວ": {
      "background": Colors.yellow,
      "text": Colors.lightBlue,
      "border": Colors.blue,
    },
    "ອົງການຈັດຕັ້ງສາກົນ(ນຳໃຊ້ສ່ວນຕົວ)": {
      "background": Colors.white,
      "text": Colors.lightBlue,
      "border": Colors.cyan,
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchTicketStatus();
  }

  Future<void> _fetchTicketStatus() async {
    try {
      final bookingRef =
          FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId);
      final bookingSnap = await bookingRef.get();

      if (bookingSnap.exists) {
        var data = bookingSnap.data()!;
        setState(() {
          collectionType = 'bookings';
          status = data['Status'] ?? 'unknown';
          nameParking = data['nameParking'] ?? '-';
          userName = data['userName'] ?? '-';
          vehicleId = data['vehicleId'] ?? '-';
          if (data['checkOutTime'] != null) {
            checkOutTime = (data['checkOutTime'] as Timestamp).toDate();
          }
        });
        await _fetchPlateTypeFromVehicle(); // Fetch vehicle details after getting booking data
      } else {
        setState(() {
          status = 'not_found';
        });
      }
    } catch (e) {
      print("Error fetching ticket status: $e");
      setState(() {
        status = 'error';
      });
    }
  }

  Future<void> _fetchPlateTypeFromVehicle() async {
    if (vehicleId == null) return; // Ensure vehicleId is not null

    try {
      final vehicleRef =
          FirebaseFirestore.instance.collection('vehicles').doc(vehicleId);
      final vehicleSnap = await vehicleRef.get();

      if (vehicleSnap.exists) {
        var data = vehicleSnap.data()!;
        setState(() {
          plateType = data['typeplate'] ?? 'unknown';
          province = data['province'] ?? 'unknown';
          charplate = data['charplate'] ?? 'unknown';
          plate = data['numberplate'] ?? 'unknown';
        });
      } else {
        setState(() {
          plateType = 'not_found';
          province = 'not_found';
          charplate = 'not_found';
          plate = 'not_found';
        });
      }
    } catch (e) {
      print("Error fetching plateType from vehicles: $e");
      setState(() {
        plateType = 'error';
        province = 'not_found';
        charplate = 'not_found';
        plate = 'not_found';
      });
    }
  }

  Future<void> _handleCheckIn() async {
    if (collectionType == null) return;

    final ticketRef =
        FirebaseFirestore.instance.collection(collectionType!).doc(widget.bookingId);

    try {
      await ticketRef.update({"Status": "check-in"});
      setState(() {
        status = "check-in";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Check-in successful!")),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      print("Error updating check-in status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update check-in status.")),
      );
    }
  }

  Future<void> _handleCheckOut() async {
    if (collectionType == null) return;

    final ticketRef =
        FirebaseFirestore.instance.collection(collectionType!).doc(widget.bookingId);
    final now = DateTime.now();

    try {
      await ticketRef.update({
        "Status": "check-out",
        "checkOutTime": FieldValue.serverTimestamp(),
      });
      setState(() {
        status = "check-out";
        checkOutTime = now;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Check-out successful!")),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      print("Error updating check-out status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update check-out status.")),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('hh:mm a, MMM d, yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final plateColor = plateColors[plateType] ?? {
      "background": Colors.grey,
      "text": Colors.white,
      "border": Colors.grey,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ticket_Status"),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF73AEF5), Color(0xFF61A4F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 10,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Scan Check',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Status: ${status == 'loading' ? 'Fetching...' : status}",
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('From: $userName', style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Ticket ID: ${widget.bookingId}',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Text('Status: $status', style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      if (checkOutTime != null)
                        Text('Check-out Time: ${_formatDateTime(checkOutTime!)}',
                            style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: plateColor["background"],
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: plateColor["border"] ?? Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            province ?? '-',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: plateColor["text"],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                charplate ?? '-',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: plateColor["text"],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                plate ?? '-',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: plateColor["text"],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (status == "pending") ...[
                   ElevatedButton(
                      onPressed: _handleCheckIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600, // สีเขียวสดใส
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30), // ขอบโค้งมนมากขึ้น
                        ),
                        elevation: 8, // เงาชัดเจน
                        shadowColor: Colors.greenAccent.shade400,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.login, size: 24, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Check-in',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ] else if (status == "check-in") ...[
                    ElevatedButton(
                      onPressed: _handleCheckOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600, // สีแดงสดใส
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: Colors.redAccent.shade400,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.logout, size: 24, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Check-out',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ] else if (status == "check-out") ...[
                    const Text(
                      "This ticket has already been checked out.",
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ] else if (status == 'not_found') ...[
                    const Text(
                      "Ticket not found.",
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ] else if (status == 'error') ...[
                    const Text(
                      "Error fetching ticket data.",
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}