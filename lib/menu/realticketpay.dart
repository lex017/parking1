import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:parking1/cash/payPage.dart';

class Realticketpay extends StatefulWidget {
  final String documentId;
  

  const Realticketpay({
    super.key,
    required this.documentId,
   
  });

  @override
  State<Realticketpay> createState() => _QrPayState();
}

class _QrPayState extends State<Realticketpay> {
  String? imageUrl; // Variable to store QR image URL
  bool isLoading = true; // Check image loading status
  late Timer _timer; // Timer instance
  int _remainingTime = 600; // Start time (10 minutes) in seconds
  int pricePerHour = 0;

  @override
  void initState() {
    super.initState();
    fetchQrImage(); // Fetch the QR code image
    startTimer(); // Start the countdown timer
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel timer when leaving the page
    super.dispose();
  }

  // Function to fetch QR code image from Cloudinary (or any source)
  Future<void> fetchQrImage() async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('parking') // 🔁 Replace with your actual collection name
        .doc(widget.documentId)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data.containsKey('qrImage')) {
        setState(() {
          imageUrl = data['qrImage']; // Fetch from Firestore
          isLoading = false;
        });
      } else {
        setState(() {
          imageUrl = null;
          isLoading = false;
        });
        print('QR URL not found in document.');
      }
    } else {
      setState(() {
        isLoading = false;
      });
      print('Document does not exist.');
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    print('Error fetching QR image: $e');
  }
}

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--; // Decrease remaining time
        });
      } else {
        _timer.cancel(); // Cancel timer when time is up
        Navigator.pop(context); // Navigate back to the previous screen
      }
    });
  }

  // Function to format time (e.g., 10:00)
  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "QR Pay",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : imageUrl == null
                      ? const Center(
                          child: Text(
                            "Failed to load image",
                            style: TextStyle(fontSize: 18, color: Colors.red),
                          ),
                        )
                      : Center(
                          child: Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
              const SizedBox(height: 20),
              // Display remaining time
              const Text(
                "Remaining Time",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                formatTime(_remainingTime),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _timer.cancel(); // Cancel the timer before navigating
                  
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text("Pay Now"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
