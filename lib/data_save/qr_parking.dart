import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:parking1/cash/payPage.dart';
import 'package:parking1/data_save/pay_parking.dart';

class QrParking extends StatefulWidget {
  final String name;
  final String address;
  final String description;
  final num? pricePerDay;
  final num? pricePerMonth;
  final num? totalPrice;
  final int price;
  final int slots;
  final int months;
  final String packageType;
  final double latitude;
  final double longitude;
  final String evSupport;
  final Uint8List parkingImageBytes;
  final Uint8List qrImageBytes;
  final File parkingImage;
  final File qrImage;


  const QrParking({
    super.key,
    required this.name,
    required this.address,
    required this.description,
    this.pricePerDay,
    this.pricePerMonth,
    this.totalPrice,
    required this.slots,
    required this.months,
    required this.packageType,
    required this.latitude,
    required this.longitude,
    required this.evSupport, required this.parkingImageBytes, required this.qrImageBytes, required this.price, required this.parkingImage, required this.qrImage, 
  });

  @override
  State<QrParking> createState() => _QrPayState();
}

class _QrPayState extends State<QrParking> {
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
                      builder: (c) => PayParking(
                        name: widget.name,
                        address: widget.address,
                        description: widget.description,
                        price: widget.price,
                        pricePerDay: widget.pricePerDay,
                        pricePerMonth: widget.pricePerMonth,
                        totalPrice: widget.totalPrice,
                        latitude: widget.latitude,
                        longitude: widget.longitude,
                        slots: widget.slots,
                        months: widget.months, // ✅ ต้องเป็น months
                        packageType: widget.packageType,
                        evSupport: widget.evSupport, 
                        parkingImageBytes: widget.parkingImageBytes, 
                        qrImageBytes: widget.qrImageBytes,
                        parkingImage: widget.parkingImage,
                        qrImage: widget.qrImage,
                        // documentId:widget.documentId, // ✅ ต้องส่ง documentId จริง
                        // ownerId: widget.ownerId, // ✅ ต้องส่ง ownerId จริง
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
                child: const Text("Pay Now"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
