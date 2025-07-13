import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:parking1/cash/payPage.dart';
import 'package:parking1/data_save/pay_addslot.dart';
import 'package:parking1/data_save/pay_parking.dart';

class QrAddslot extends StatefulWidget {
  final int additionalSlots;
  final int remainingDays;
  final num pricePerDay;
  final num totalPrice;
  final String parkingId;


  const QrAddslot({
    super.key, required this.additionalSlots, required this.remainingDays, required this.pricePerDay, required this.totalPrice, required this.parkingId, 
   
  });

  @override
  State<QrAddslot> createState() => _QrPayState();
}

class _QrPayState extends State<QrAddslot> {
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
  // Function to fetch QR code image from Cloudinary (or any source)
  Future<void> fetchQrImage() async {
    try {
      const String cloudinaryUrl =
          'https://res.cloudinary.com/doiq3nkso/image/upload/v1736478510/zgpbt7fp1w9d9tua7ujp.jpg'; // Placeholder URL
      setState(() {
        imageUrl = cloudinaryUrl; // Set the URL
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching image: $e');
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
                  if (_timer.isActive) {
                    _timer.cancel(); // Cancel the timer safely
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (c) => PayAddslot(
                        additionalSlots: widget.additionalSlots,
                      remainingDays: widget.remainingDays,
                      pricePerDay: widget.pricePerDay,
                      totalPrice: widget.totalPrice, parkingId: widget.parkingId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: Text("Pay Now",style: TextStyle(color: Colors.white),),
              )
            ],
          ),
        ),
      ),
    );
  }
}
