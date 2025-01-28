import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BillPage extends StatefulWidget {
  const BillPage({super.key});

  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  // Sample bill data for QR Code
  final Map<String, String> billData = {
    "Date": "04-Jan-2025",
    "Transaction ID": "TXN123456789",
    "Payment Method": "Credit Card",
    "Parking Fee": "20,000 KIP",
    "Service Fee": "5,000 KIP",
    "Total Amount": "25,000 KIP"
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Bill",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Transaction Details
            const Text(
              "Transaction Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildDetailRow("Date:", billData["Date"]!),
            _buildDetailRow("Transaction ID:", billData["Transaction ID"]!),
            _buildDetailRow("Payment Method:", billData["Payment Method"]!),
            const Divider(height: 30, thickness: 1),

            // Items Section
            const Text(
              "Items",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildItemRow("Parking Fee", billData["Parking Fee"]!),
            _buildItemRow("Service Fee", billData["Service Fee"]!),
            const Divider(height: 30, thickness: 1),

            // Total Amount
            _buildDetailRow(
              "Total Amount:",
              billData["Total Amount"]!,
              isBold: true,
              fontSize: 20,
            ),
            const SizedBox(height: 30),

            // QR Code Section
            Center(
              child: QrImageView(
                data: billData.toString(),
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 40),

            // Download and Share Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Downloading Bill..."),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text("Download"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Sharing Bill..."),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text("Share"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for transaction/item details
  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for items
  Widget _buildItemRow(String itemName, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            itemName,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
