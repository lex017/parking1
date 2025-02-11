import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BillPage extends StatefulWidget {
  final String transactionId;
  const BillPage({super.key, required this.transactionId});

  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  Map<String, dynamic>? billData;

  @override
  void initState() {
    super.initState();
    _fetchBillData();
  }

  Future<void> _fetchBillData() async {
    print("Fetching payment with ID: ${widget.transactionId}"); // Debugging log

    try {
      DocumentSnapshot document = await FirebaseFirestore.instance
          .collection('payments')
          .doc(widget.transactionId)
          .get();

      if (document.exists) {
        setState(() {
          billData = document.data() as Map<String, dynamic>;
        });
      } else {
        print("No document found for this ID.");
      }
    } catch (e) {
      print("Error fetching payment data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Bill", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: billData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Transaction Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildDetailRow("Date:", _formatTimestamp(billData!["timestamp"])),
                  _buildDetailRow("Transaction ID:", widget.transactionId),
                  _buildDetailRow("Payment Method:", "Bank Transfer"),
                  const Divider(height: 30, thickness: 1),
                  const Text("Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildItemRow("Package Hours", "${billData!["packageHours"] ?? "N/A"} hours"),
                  _buildItemRow("Price", "${billData!["price"] ?? "N/A"}"),
                  const Divider(height: 30, thickness: 1),
                  _buildDetailRow("Total Amount:", "${billData!["totalAmount"] ?? "N/A"}", isBold: true, fontSize: 20),
                  const SizedBox(height: 30),
                  Center(
                    child: QrImageView(
                      data: billData.toString(),
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildItemRow(String itemName, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(itemName, style: const TextStyle(fontSize: 16)),
          Text(price, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
  }
}
