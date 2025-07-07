// lib/global_booking_listener.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

class GlobalTimeoutChecker extends StatefulWidget {
  final Widget child;
  const GlobalTimeoutChecker({super.key, required this.child});

  @override
  State<GlobalTimeoutChecker> createState() => _GlobalTimeoutCheckerState();
}

class _GlobalTimeoutCheckerState extends State<GlobalTimeoutChecker>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkTimeoutOnLaunch(); // ตรวจสอบตอนเปิดแอป
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkTimeoutOnResume(); // ตรวจสอบตอนแอปกลับมาจาก background
    }
  }

  void _checkTimeoutOnLaunch() async {
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
      final DateTime timeout = (data['timeout'] as Timestamp).toDate();
      final now = DateTime.now();

      if (now.isAfter(timeout)) {
        _showTimeoutPopup();
      }
    }
  }

  void _checkTimeoutOnResume() => _checkTimeoutOnLaunch();

  void _showTimeoutPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⏳ การจองหมดเวลาแล้ว"),
        content: const Text("กรุณาทำการจองใหม่อีกครั้ง"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ตกลง"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
