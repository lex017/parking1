import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parking1/homepage.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BuyTicket extends StatefulWidget {
  final String bookingId;

  const BuyTicket({super.key, required this.bookingId});

  @override
  State<BuyTicket> createState() => _BuyTicketState();
}

class _BuyTicketState extends State<BuyTicket> {
  late Future<Map<String, dynamic>> _ticketFuture;
  Timer? _timer;
  int remainingSeconds = 30 * 60; // 30 minutes in seconds

  @override
  void initState() {
    super.initState();
    _ticketFuture = fetchTicketData();
    startTimer();
  }

   /// Fetch ticket and payment details
  Future<Map<String, dynamic>> fetchTicketData() async {
    DocumentSnapshot bookingSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .get();

    if (!bookingSnapshot.exists) {
      throw Exception("Booking not found");
    }

    var bookingData = bookingSnapshot.data() as Map<String, dynamic>;
    String transactionId = bookingData['paymentId'] ?? '';
    var parkingStatus = bookingData['parkingStatus'] ?? 'pending';

    // Fetch payment data using transactionId
    DocumentSnapshot paymentSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .doc(transactionId)
        .get();

    Map<String, dynamic> paymentData = paymentSnapshot.exists
        ? paymentSnapshot.data() as Map<String, dynamic>
        : {};

    // Listen to status changes in Firestore
    FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        String newStatus = snapshot['parkingStatus'] ?? 'pending';

        if (newStatus == 'check-in' || newStatus == 'check-out') {
          stopTimer(); // Stop timer if status is "check-in"
        } else if (newStatus == 'pending') {
          startTimer(); // Start timer if status is "pending"
        }

        setState(() {
          parkingStatus = newStatus;
        });
      }
    });

    return {
      'booking': bookingData,
      'payment': paymentData,
    };
  }

  /// Starts a countdown timer (30 minutes) only if status is "pending"
  void startTimer() {
    _timer?.cancel(); // Prevent duplicate timers
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        await updateParkingStatusToCheckout();
      }
    });
  }

  /// Stops the countdown timer
  void stopTimer() {
    _timer?.cancel();
    setState(() {
      remainingSeconds = 30 * 60; // Reset timer
    });
  }

  /// Updates Firestore status to 'checkout' when time expires
  Future<void> updateParkingStatusToCheckout() async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .update({'parkingStatus': 'checkout'});

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Time Expired"),
          content: const Text("Your 30-minute parking session has ended."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const Homepage()),
                );
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  /// Formats remaining time into MM:SS format
  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int sec = seconds % 60;
    return "$minutes:${sec.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _ticketFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            }
            if (!snapshot.hasData) {
              return const Text("No booking found");
            }

            var bookingData = snapshot.data!['booking'];
            var paymentData = snapshot.data!['payment'];

            String userName = bookingData['userName'] ?? 'Unknown';
            String bookingDate = bookingData['bookingDate'] ?? 'N/A';
            String bookingTime = bookingData['bookingTime'] ?? 'N/A';
            String transactionId = bookingData['paymentId'] ?? 'N/A';
            String parkingStatus = bookingData['parkingStatus'] ?? 'N/A';
            String amount = paymentData['amount'] ?? '0.00';

            String qrData =
                "BookingID: ${widget.bookingId}\nUser: $userName\nDate: $bookingDate\nTime: $bookingTime\nPaymentID: $transactionId\nParking Status: $parkingStatus\nAmount: $amount";

            return Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.yellow[700],
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 5, spreadRadius: 2),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.local_parking, size: 40, color: Colors.black),
                      SizedBox(width: 10),
                      Text(
                        "PARKING TICKET",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // QR Code
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 150,
                  ),
                  const SizedBox(height: 20),

                  // Booking Date
                  Text(
                    bookingDate,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // User and Time Information
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("From:", style: TextStyle(fontSize: 16)),
                          Text(userName,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("Time:", style: TextStyle(fontSize: 16)),
                          Text(bookingTime,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Amount Paid
                  Text("PAID: $amount Kip",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  // Parking Status
                  Text("Parking Status: $parkingStatus",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Countdown Timer Display
                  Text(
                    "Time Left: ${formatTime(remainingSeconds)}",
                    style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // "Thank You" Message
                  const Text("THANK YOU AND HAVE A SAFE TRIP!", style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 20),

                  // Back to Main Page Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const Homepage()),
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text("Main Page"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
