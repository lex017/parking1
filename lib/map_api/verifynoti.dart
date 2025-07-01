import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // เริ่มใช้งาน android_alarm_manager_plus
  await AndroidAlarmManager.initialize();

  // ตั้งค่า local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // ตั้ง Alarm ให้เช็ค Firestore ทุก 15 นาที
  await AndroidAlarmManager.periodic(
    const Duration(minutes: 15),
    0, // alarm ID
    checkBookingStatus,
    wakeup: true,
    exact: true,
  );

  runApp(const MyApp());
}

// ฟังก์ชันที่ Alarm จะเรียกทุก 15 นาที
Future<void> checkBookingStatus() async {
  print("Alarm fired! Checking booking status...");

  // ตัวอย่างเช็ค booking ที่สถานะ pending
  var snapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .where('status', isEqualTo: 'pending')
      .limit(1)
      .get();

  if (snapshot.docs.isNotEmpty) {
    // ถ้ามี booking pending ให้แจ้งเตือน
    await showNotification(
      title: 'มีการจองที่รอการยืนยัน',
      body: 'กรุณาตรวจสอบการชำระเงินของคุณ',
    );
  }
}

Future<void> showNotification({required String title, required String body}) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'booking_channel',
    'Booking Notifications',
    channelDescription: 'แจ้งเตือนสถานะการจอง',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    notificationDetails,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Android Alarm Manager + Firestore Example'),
        ),
      ),
    );
  }
}
