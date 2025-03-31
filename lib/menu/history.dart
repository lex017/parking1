import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parking1/drawer.dart';
import 'package:parking1/menu/detailHistory.dart'; // Import your details_history page

class history extends StatefulWidget {
  const history({super.key});

  @override
  State<history> createState() => _HistoryState();
}

class _HistoryState extends State<history> {
  late Stream<List<Map<String, dynamic>>> _historyStream;

  @override
  void initState() {
    super.initState();
    _historyStream = fetchHistoryData();
  }

  Stream<List<Map<String, dynamic>>> fetchHistoryData() {
  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  if (currentUserId == null) {
    return Stream.value([]); // Return an empty list if the user is not logged in
  }

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('userId', isEqualTo: currentUserId) // ✅ Filter by current user's ID
      .snapshots()
      .asyncMap((snapshot) async {
    List<Map<String, dynamic>> historyList = [];
    for (var doc in snapshot.docs) {
      var bookingData = doc.data();
      String transactionId = bookingData['paymentId'] ?? '';

      DocumentSnapshot paymentSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .doc(transactionId)
          .get();

      Map<String, dynamic> paymentData = paymentSnapshot.exists
          ? paymentSnapshot.data() as Map<String, dynamic>
          : {};

      historyList.add({
        'booking': bookingData,
        'payment': paymentData,
        'bookingDocId': doc.id, // Booking document ID
      });
    }
    return historyList;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _historyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No history found."));
          }

          List<Map<String, dynamic>> historyList = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              var bookingData = historyList[index]['booking'];
              var paymentData = historyList[index]['payment'];
              var bookingDocId = historyList[index]['bookingDocId']; // get Doc Id

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailHistory(
                        bookingData: bookingData,
                        paymentData: paymentData,
                        bookingDocId: bookingDocId, // Pass the document ID
                      ),
                    ),
                  );
                },
                child: TicketWidget(
                  title: 'Parking Ticket',
                  subtitle: 'Location: ${bookingData['nameparking'] ?? 'N/A'}',
                  date: bookingData['bookingDate'] ?? 'N/A',
                  seat: bookingData['Status'] ?? 'N/A',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TicketWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String seat;

  const TicketWidget({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.seat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.local_parking, color: Colors.white),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(double.infinity, 20),
            painter: DashedLinePainter(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date'),
                        Text(
                          date,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status'),
                        Text(
                          seat,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}