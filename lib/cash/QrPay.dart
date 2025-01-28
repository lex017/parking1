import 'package:flutter/material.dart';
import 'dart:async';

import 'package:parking1/cash/payPage.dart';


class QrPay extends StatefulWidget {
  const QrPay({super.key});

  @override
  State<QrPay> createState() => _QrPayState();
}

class _QrPayState extends State<QrPay> {
  String? imageUrl; // ใช้สำหรับเก็บ URL ของ QR
  bool isLoading = true; // เช็คสถานะการโหลดภาพ
  late Timer _timer; // ตัวจับเวลา
  int _remainingTime = 600; // เวลาเริ่มต้น (10 นาที) ในวินาที
  int? selectedHours = 1; // Example initialization of selectedHours

  @override
  void initState() {
    super.initState();
    fetchQrImage(); // โหลดภาพ QR Code
    startTimer(); // เริ่มตัวจับเวลา
  }

  @override
  void dispose() {
    _timer.cancel(); // ยกเลิกตัวจับเวลาเมื่อออกจากหน้า
    super.dispose();
  }

  // ฟังก์ชันโหลด QR จาก Cloudinary
  Future<void> fetchQrImage() async {
    try {
      const String cloudinaryUrl =
          'https://res.cloudinary.com/doiq3nkso/image/upload/v1736478510/zgpbt7fp1w9d9tua7ujp.jpg'; // URL ของ QR
      setState(() {
        imageUrl =
            cloudinaryUrl; // ตั้งค่า URL ตรงนี้ (สมมติว่า URL ใช้งานได้โดยตรง)
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
          _remainingTime--; // ลดเวลาที่เหลือ
        });
      } else {
        _timer.cancel(); // ยกเลิกตัวจับเวลา
        Navigator.pop(context); // ส่งผู้ใช้กลับหน้าหลัก
      }
    });
  }

  // ฟังก์ชันฟอร์แมตเวลา (เช่น 10:00)
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
      body: Column(
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
          // แสดงเวลาที่เหลือ
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
            onPressed: selectedHours == null
                ? null
                : () {
                    _timer.cancel(); // Cancel the timer before navigating
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (c) => PayPage(
                            packageHours: selectedHours!), // Pass selectedHours
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  selectedHours == null ? Colors.grey : Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            child: const Text("Pay Now"),
          ),
        ],
      ),
    );
  }
}

class NextPage extends StatelessWidget {
  const NextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Next Page"),
      ),
      body: const Center(
        child: Text(
          "This is the next page.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
