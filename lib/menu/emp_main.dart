import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:parking1/menu/employeescan.dart';

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

  List<Map<String, dynamic>> scanRecords = [];
  double _totalMoney = 0.0;
  String _currentTime = DateFormat('hh:mm a').format(DateTime.now()); // Removed seconds

  @override
  void initState() {
    super.initState();
    empId = widget.empId;
    if (kDebugMode) {
      print('Logged-in empId: $empId');
    }
    _updateTime();
  }

  void _updateTime() {
    Future.delayed(const Duration(minutes: 1), () { // Updated to minutes
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('hh:mm a').format(DateTime.now()); // Removed seconds
          _updateTime();
        });
      }
    });
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
      MaterialPageRoute(builder: (context) => const EmployeeScan()),
    );
    if (result != null && result is double) {
      setState(() {
        String formattedTime = DateFormat('hh:mm a').format(DateTime.now()); // Removed seconds
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text("Employee Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo[800],
        elevation: 0,
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
          final profileImage = userData['profileImage'] ??
              'https://via.placeholder.com/150';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileSection(profileImage, firstName, lastName),
                const SizedBox(height: 20),
                _buildScanSummary(),
                const SizedBox(height: 20),
                Text(
                  'Current Time: $_currentTime',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(String profileImage, String firstName, String lastName) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 70,
                backgroundImage: NetworkImage(profileImage),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "$firstName $lastName",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _performScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Scan Ticket", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanSummary() {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Today's Scans",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Divider(color: Colors.white38),
            Text(
              "Total Money: ${_totalMoney.toStringAsFixed(2)} \ Kip",
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: scanRecords.isEmpty
                  ? const Center(
                      child: Text("No scans yet",
                          style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: scanRecords.length,
                      itemBuilder: (context, index) {
                        final scan = scanRecords[index];
                        return ListTile(
                          leading: const Icon(Icons.qr_code, color: Colors.white),
                          title: Text(
                            "\$${scan['price'].toStringAsFixed(2)}",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18),
                          ),
                          subtitle: Text(
                            scan['time'],
                            style: const TextStyle(color: Colors.white54),
                          ),
                        );
                      }),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _resetScans,
              icon: const Icon(Icons.refresh),
              label: const Text("Reset Scans"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}