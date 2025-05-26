import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:parking1/menu/Help.dart';
import 'package:parking1/menu/detail_employee.dart';
import 'package:parking1/menu/emp_generate.dart';
import 'package:parking1/menu/emp_notification.dart';
import 'package:parking1/menu/emp_pending.dart';
import 'package:parking1/menu/emp_verify.dart';
import 'package:parking1/menu/employee_login.dart';
import 'package:parking1/menu/employeescan.dart';
import 'package:parking1/menu/myreal_ticket.dart';
import 'package:shared_preferences/shared_preferences.dart';

class emp_main extends StatefulWidget {
  final String empId;
  const emp_main({super.key, required this.empId});

  @override
  State<emp_main> createState() => _EmpMainState();
}

class _EmpMainState extends State<emp_main> {
  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  late String empId;
  String? locationId;

  List<Map<String, dynamic>> scanRecords = [];
  double _totalMoney = 0.0;
  String _currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    // Assume you fetched this from Firebase Auth or Firestore
    String employeeLocationId = widget.empId;

    // Start listening for relevant bookings
    listenForBookings(employeeLocationId);
    empId = widget.empId;
    if (kDebugMode) {
      print('Logged-in empId: $empId');
    }
    _getRealTimeDate();
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  void _getRealTimeDate() {
    {
      setState(() {
        _currentDate = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
      });
    }
    ;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('emp_id');
    await prefs.remove('rememberMe');

    setState(() {
      // Optional: Update state if necessary
    });

    // Navigate to the login page
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => emp_login()),
      (route) => route.isFirst, // Keep only the first route (HomePage)
    );
  }

  Future<void> help() async {
    setState(() {
      // Optional: Update state if necessary
    });

    // Navigate to the login page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Help()),
    );
  }

  Stream<DocumentSnapshot> getEmployeeData() {
    return FirebaseFirestore.instance
        .collection('employees')
        .doc(empId)
        .snapshots();
  }

  Future<void> _performScan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EmployeeScan(
                empId: empId,
              )),
    );
    if (result != null && result is double) {
      setState(() {
        String formattedTime =
            DateFormat('hh:mm a').format(DateTime.now()); // Removed seconds
        scanRecords.insert(0, {'price': result, 'time': formattedTime});
        _totalMoney += result;
      });
    }
  }

  void _resetScans() {
    setState(() {
      scanRecords.clear();
      _totalMoney = 0.0;
    });
  }

  Future<String> getParkingName(String locationId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('parking')
          .doc(locationId)
          .get();

      if (snapshot.exists) {
        return snapshot['nameparking'] ?? 'Unknown Parking';
      } else {
        return 'Unknown Parking';
      }
    } catch (e) {
      print("Error fetching parking name: $e");
      return 'Unknown Parking';
    }
  }

  Future<String> _getLocationId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('employees')
        .doc(empId)
        .get();

    return snapshot['locationId'] ?? 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Employee Profile",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                logout();
              } else if (value == 'Help') {
                help();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'Help',
                child: Row(
                  children: [
                    Icon(Icons.help, color: Colors.black),
                    SizedBox(width: 10),
                    Text("Help")
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text("Logout")
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: getEmployeeData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No employee data found."));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final firstName = userData['firstname'] ?? 'N/A';
          final lastName = userData['lastname'] ?? 'N/A';
          final locationId = userData['locationId'] ?? 'N/A';

          return FutureBuilder<String>(
            future: getParkingName(locationId),
            builder: (context, parkingSnapshot) {
              String parkingName = parkingSnapshot.data ?? 'Loading...';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileSection(userData['profileImage'], firstName,
                        lastName, parkingName),
                    const SizedBox(height: 30),
                    Text(
                      'Function',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700,color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 10),
                    buttonFour(context),
                    const SizedBox(height: 20),
                    _buildScanSummary(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void listenForBookings(String employeeLocationId) {
    FirebaseFirestore.instance
        .collection('bookings')
        .snapshots()
        .listen((querySnapshot) {
      for (var docChange in querySnapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          final booking = docChange.doc.data();
          final bookingLocationId = booking?['locationId'];

          // Only show notification if employee has a locationId and it matches the booking
          if (employeeLocationId.isNotEmpty &&
              bookingLocationId == employeeLocationId) {
            showLocalNotification(
              title: 'New Booking Alert',
              body: 'A new booking was made at your location.',
            );
          }
        }
      }
    });
  }

  Future<void> showLocalNotification(
      {required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'channel_id',
      'Booking Alerts',
      channelDescription: 'Notification for new bookings',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  Widget _buildProfileSection(String? profileImage, String firstName,
      String lastName, String locationId) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
            color: Colors.blueAccent, width: 2), // Border around the card
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image with Border
            Container(
              padding:
                  const EdgeInsets.all(4), // Space between border and image
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundImage:
                    (profileImage != null && profileImage.isNotEmpty)
                        ? NetworkImage(profileImage)
                        : const AssetImage('assets/default_profile.png')
                            as ImageProvider,
              ),
            ),
            const SizedBox(width: 20), // Spacing between image and text

            // Name and Button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$firstName $lastName",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Status: Employee",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Location: $locationId",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "ID: $empId",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                  Divider(),
                  const SizedBox(height: 3),
                  Text(
                    "Count Scan: $_totalMoney",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Date: $_currentDate", // ✅ Fixed reference to date
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget DashboardButton({
    required String iconPath,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.blueAccent,
              width: 1.0,
            ),
          ),
          margin: EdgeInsets.zero,
          child: Container(
            width: 140,
            height: 140,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  iconPath,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                const SizedBox(height: 18),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buttonFour(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: _buildDashboardButton(context,
                      iconPath: 'assets/images/history1.png',
                      label: 'ປະຫວັດ', onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => DetailEmployee()),
                );
              })),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildDashboardButton(context,
                      iconPath: 'assets/images/ticket1.png',
                      label: 'ສ້າງປີ້', onPressed: () async {
                String locationId = await _getLocationId();

                // Pass locationId to EmpGenerate screen after fetching it
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EmpGenerate(
                      empId: empId,
                      locationId: locationId,
                    ),
                  ),
                );
              })),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildDashboardButton(context,
                      iconPath: 'assets/images/ticket.png',
                      label: 'ປີ້ປັດຈຸບັນ', onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => MyrealTicket(
                            empId: empId,
                          )),
                );
              })),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: _buildDashboardButton(context,
                      iconPath: 'assets/images/online-booking.png',
                      label: 'Verify', onPressed: () async {
                String locationId = await _getLocationId();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        EmpNotification(empId: empId, locationId: locationId),
                  ),
                );
              })),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildDashboardButton(context,
                      iconPath: 'assets/images/document.png',
                      label: 'pending', onPressed: () async {
                String locationId = await _getLocationId();
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => EmpPending(
                            empId: empId,
                            locationId: locationId,
                          )),
                );
              })),
              // To keep the row with 2 buttons only, you can add a Spacer or empty container here if needed
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

// Helper method to build styled button
 Widget _buildDashboardButton(
  BuildContext context, {
  required String iconPath,
  required String label,
  required VoidCallback onPressed,
}) {
  return InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: 48,
            height: 48,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildScanSummary() {
    return Column(
      children: [
        SizedBox(
          width: 400, // Full width
          height: 100, // Increased height
          child: ElevatedButton.icon(
            onPressed: _performScan,
            icon: const Icon(Icons.qr_code_scanner,
                size: 30, color: Colors.white), // Added icon
            label: const Text(
              "Scan Ticket",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // More rounded
              ),
            ),
          ),
        ),
      ],
    );
  }
}
