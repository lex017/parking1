// GlobalTimerBanner.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GlobalTimerBanner extends StatefulWidget {
  final Widget child;
  const GlobalTimerBanner({super.key, required this.child});

  @override
  State<GlobalTimerBanner> createState() => _GlobalTimerBannerState();
}

class _GlobalTimerBannerState extends State<GlobalTimerBanner> {
  DateTime? timeout;
  bool isExpired = false;

  @override
  void initState() {
    super.initState();
    _startCountdownFromFirestore();
  }

  void _startCountdownFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .where('Status', isEqualTo: 'pending')
        .orderBy('timeout')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      final ts = data['timeout'] as Timestamp;
      setState(() {
        timeout = ts.toDate();
      });
      _startTimer();
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || timeout == null) return;

      final now = DateTime.now();
      if (now.isAfter(timeout!)) {
        setState(() {
          isExpired = true;
        });
      } else {
        _startTimer(); // Continue looping
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter, // ต้องมี Directionality ครอบไว้ใน main
      children: [
        widget.child,
        if (timeout != null && !isExpired)
          Container(
            width: double.infinity,
            color: Colors.amber,
            padding: const EdgeInsets.all(8),
            child: Text(
              "⏰ เหลือเวลา ${timeout!.difference(DateTime.now()).inMinutes} นาทีในการจอง",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        if (isExpired)
          Container(
            width: double.infinity,
            color: Colors.red,
            padding: const EdgeInsets.all(8),
            child: const Text(
              "⛔ การจองของคุณหมดเวลาแล้ว",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
      ],
    );
  }
}
