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

  @override
  void initState() {
    super.initState();
    _ticketFuture = fetchTicketData();
  }

  Future<Map<String, dynamic>> fetchTicketData() async {
    // Fetch booking data
    DocumentSnapshot bookingSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .get();

    if (!bookingSnapshot.exists) {
      throw Exception("Booking not found");
    }

    var bookingData = bookingSnapshot.data() as Map<String, dynamic>;
    String transactionId = bookingData['paymentId'] ?? '';

    // Fetch payment data using transactionId
    DocumentSnapshot paymentSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .doc(transactionId)
        .get();

    Map<String, dynamic> paymentData = paymentSnapshot.exists
        ? paymentSnapshot.data() as Map<String, dynamic>
        : {};

    return {
      'booking': bookingData,
      'payment': paymentData,
    };
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
              return CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            }
            if (!snapshot.hasData) {
              return Text("No booking found");
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
                "BookingID: ${widget.bookingId}\nUser: $userName\nDate: $bookingDate\nTime: $bookingTime\nPaymentID: $transactionId\nparkingStatus: $parkingStatus\nAmount: $amount";

            return Container(
              width: 300,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.yellow[700],
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26, blurRadius: 5, spreadRadius: 2),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with Icon and Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_parking, size: 40, color: Colors.black),
                      SizedBox(width: 10),
                      Text(
                        "PARKING TICKET",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // QR Code
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 150, // Increased QR code size
                  ),
                  SizedBox(height: 20),

                  // Booking Date
                  Text(
                    bookingDate,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 15),

                  // User and Time Information
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("From:", style: TextStyle(fontSize: 16)),
                          Text(userName,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Time:", style: TextStyle(fontSize: 16)),
                          Text(bookingTime,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Amount Paid
                  Text("PAID: $amount Kip",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 15),

                  // Parking Status
                  Text("Parking Status: $parkingStatus",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),

                  // "Thank You" Message
                  Text("THANK YOU AND HAVE A SAFE TRIP!",
                      style: TextStyle(fontSize: 14)),
                  SizedBox(height: 20),

                  // Back to Main Page Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => const Homepage()));
                    },
                    icon: Icon(Icons.home),
                    label: Text("Main Page"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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