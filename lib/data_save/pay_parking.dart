import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:parking1/chose/ownerMain.dart';
import 'package:parking1/homepage.dart';
import 'package:time_picker_spinner/time_picker_spinner.dart';

class PayParking extends StatefulWidget {
  final String name;
  final String address;
  final String openTime;
  final String closeTime;
  final String description;
  final String landmark;
  final num? pricePerDay;
  final num? pricePerMonth;
  final num? totalPrice;
  final int slots;
  final int price;
  final int months;
  final String packageType;
  final double latitude;
  final double longitude;
  final String evSupport;
  final Uint8List parkingImageBytes;
  final Uint8List qrImageBytes;
  final File parkingImage;
  final File qrImage;

  const PayParking({
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
    required this.evSupport,
    required this.parkingImageBytes,
    required this.qrImageBytes,
    required this.price,
    required this.parkingImage,
    required this.qrImage,
    required this.landmark, required this.openTime, required this.closeTime,
  });

  @override
  State<PayParking> createState() => _PayPageState();
}

class _PayPageState extends State<PayParking> {
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isButtonDisabled = false;
  DateTime now = DateTime.now();


  final TextEditingController timeController = TextEditingController();

  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";

  @override
  void initState() {
    super.initState();
  }

  Future<String> generateLocationId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('parking')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return "location1";
    } else {
      final lastId = snapshot.docs.first.id; // เช่น "location7"
      final number = int.tryParse(lastId.replaceAll('location', '')) ?? 0;
      return "location${number + 1}";
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        if (kIsWeb) {
          final Uint8List bytes = await pickedFile.readAsBytes();
          setState(() {
            _imageBytes = bytes;
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = File(pickedFile.path);
            _imageBytes = null;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
      }
    } catch (e) {
      print("Error selecting image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error selecting image')),
      );
    }
  }

  void _pickTime() {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      DateTime selectedTime = DateTime.now();

      return Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: TimePickerSpinner(
                is24HourMode: true, // Set to true for 24-hour mode
                isShowSeconds: true, // ✅ Show seconds
                normalTextStyle:
                    const TextStyle(fontSize: 18, color: Colors.grey),
                highlightedTextStyle:
                    const TextStyle(fontSize: 24, color: Colors.black),
                spacing: 40,
                itemHeight: 60,
                isForce2Digits: true,
                time: selectedTime,
                onTimeChange: (time) {
                  selectedTime = time;
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // ✅ Format as HH:mm:ss (24-hour format)
                final formatted = DateFormat('HH:mm:ss').format(selectedTime);
                setState(() {
                  timeController.text = formatted;
                });
                Navigator.pop(context);
              },
              child: const Text("Confirm"),
            ),
          ],
        ),
      );
    },
  );
}

  Future<String?> _uploadImageToCloudinary() async {
    try {
      if (_selectedImage == null && _imageBytes == null) {
        return null;
      }

      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset;

      if (_imageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', _imageBytes!));
      } else if (_selectedImage != null) {
        request.files.add(
            await http.MultipartFile.fromPath('file', _selectedImage!.path));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final data = jsonDecode(responseData.body);
        return data['secure_url'];
      } else {
        print("Cloudinary Upload Failed: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      return null;
    }
  }

  bool isParkingOpen(String openTime, String closeTime) {
  final now = TimeOfDay.now();

  final open = TimeOfDay(
    hour: int.parse(openTime.split(":")[0]),
    minute: int.parse(openTime.split(":")[1]),
  );
  final close = TimeOfDay(
    hour: int.parse(closeTime.split(":")[0]),
    minute: int.parse(closeTime.split(":")[1]),
  );

  // Compare time
  if (now.hour > open.hour || (now.hour == open.hour && now.minute >= open.minute)) {
    if (now.hour < close.hour || (now.hour == close.hour && now.minute <= close.minute)) {
      return true; // Parking is open
    }
  }
  return false;
}

  Future<void> _savebillAndBooking() async {
    setState(() {
      _isButtonDisabled = true;
    });

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in.")),
      );
      return;
    }

    if (timeController.text.isEmpty ||
        (_selectedImage == null && _imageBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fill all fields and upload an image.")),
      );
      return;
    }

    String? imageUrl = await _uploadImageToCloudinary();
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image upload failed.")),
      );
      return;
    }

    Future<String> uploadFileToCloudinary(File file) async {
      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData.body);
        return data['secure_url'];
      } else {
        throw Exception('Failed to upload image: ${response.reasonPhrase}');
      }
    }

    String parkingImage = await uploadFileToCloudinary(widget.parkingImage);
    String qrImage = await uploadFileToCloudinary(widget.qrImage);
    User? currentUser = FirebaseAuth.instance.currentUser;
    String ownerId = currentUser?.uid ?? 'unknown_owner';
    String locationId = await generateLocationId();
    String transactionId = "bill$locationId";

    try {
      // Save to parking_bill collection
      await FirebaseFirestore.instance
          .collection('parking_bill')
          .doc(transactionId)
          .set({
        'nameparking': widget.name,
        'ownerId': ownerId,
        'price': widget.price,
        'pricePerDay': widget.pricePerDay ?? 0,
        'pricePerMonth': widget.pricePerMonth ?? 0,
        'totalPrice': widget.totalPrice ?? 0,
        'car_slot': widget.slots,
        'imageBill': imageUrl,
        'openTime': widget.openTime,
        'closeTime': widget.closeTime,
        'timezone': "Asia/Bangkok",
        "isOpen": true, 
        'status': "pending",
        'pagekage': "standard",
        'months': widget.months,
        'packageType': widget.packageType,
        'tag': widget.evSupport,
        'locationId': locationId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Save to parking collection
      await FirebaseFirestore.instance
          .collection('parking')
          .doc(locationId)
          .set({
        'nameparking': widget.name,
        'ownerId': ownerId,
        'address': widget.address,
        'description': widget.description,
        'landmark': widget.landmark,
        'price': widget.price,
        'pricePerDay': widget.pricePerDay ?? 0,
        'pricePerMonth': widget.pricePerMonth ?? 0,
        'totalPrice': widget.totalPrice ?? 0,
        'car_slot': widget.slots,
        'status': "N/A",
        'months': widget.months,
        'date': DateFormat('d/M/yyyy').format(DateTime.now()),
        'time': timeController.text,
        'qrImage': qrImage,
        'imageUrl': parkingImage,
        'packageType': widget.packageType,
        'location': GeoPoint(widget.latitude, widget.longitude),
        'tag': widget.evSupport,
        'isActive': true, // Mark as inactive initially
        'openTime': widget.openTime,
        'closeTime': widget.closeTime,
        'timezone': "Asia/Bangkok",
        "isOpen": true, 
        'packageStartDate': FieldValue.serverTimestamp(), // Record when added
        'packageMonths': widget.months,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Bill submitted. Waiting for verification...")),
      );

      _showVerificationDialog(transactionId);
    } catch (error) {
      print("Error saving bill or booking: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save booking. Try again.")),
      );
      setState(() {
        _isButtonDisabled = false;
      });
    }
  }

  Future<void> deactivateExpiredParkings() async {
    final now = DateTime.now();

    final query = await FirebaseFirestore.instance
        .collection('parking')
        .where('isActive', isEqualTo: true)
        .get();

    for (var doc in query.docs) {
      final data = doc.data();
      final startDate = (data['packageStartDate'] as Timestamp).toDate();
      final months = data['packageMonths'] ?? 1;

      final expiryDate = addMonths(startDate, months);

      if (now.isAfter(expiryDate)) {
        await doc.reference.update({'isActive': false});
      }
    }
  }

  DateTime addMonths(DateTime date, int monthsToAdd) {
    int newMonth = date.month + monthsToAdd;
    int yearOffset = (newMonth - 1) ~/ 12;
    int finalMonth = ((newMonth - 1) % 12) + 1;
    int finalYear = date.year + yearOffset;

    int day = date.day;
    int lastDayOfMonth = DateTime(finalYear, finalMonth + 1, 0).day;
    return DateTime(
        finalYear, finalMonth, day > lastDayOfMonth ? lastDayOfMonth : day);
  }

  void _showVerificationDialog(String transactionId) {
    bool isVerified = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            FirebaseFirestore.instance
                .collection('parking_bill')
                .doc(transactionId)
                .snapshots()
                .listen((docSnapshot) {
              if (!isVerified &&
                  docSnapshot.exists &&
                  docSnapshot.data()?['status'] == "success") {
                isVerified = true; // persist success

                Future.delayed(const Duration(seconds: 2), () {
                  // Navigator.of(context, rootNavigator: true).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ownerMain()),
                  );
                });
              }
            });
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
              title: Center(
                child: Text(
                  isVerified ? "Bill Successful" : "Bill Verification",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isVerified ? Colors.green : Colors.blueAccent,
                  ),
                ),
              ),
              content: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isVerified
                        ? [Colors.green.shade50, Colors.white]
                        : [Colors.blue.shade50, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isVerified
                        ? Lottie.network(
                            'https://lottie.host/849ddcf8-8e91-46e2-8b7d-294c25f98b8f/C3UHzTkWtW.json',
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          )
                        : Lottie.network(
                            'https://lottie.host/0f94c2a0-04ba-4ac7-b980-c529bd4fcc62/eLTNAOsywB.json',
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                    const SizedBox(height: 20),
                    Text(
                      isVerified
                          ? "Bill Verified Successfully!"
                          : "Waiting for bill verification...",
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isVerified
                          ? "Thank you for your bill."
                          : "Please do not close the app.",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Center(
                        child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blueAccent, // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12.0), // Rounded corners
                        ),
                        padding: EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 20.0), // Button padding
                        elevation: 5, // Shadow effect
                      ),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const Homepage(), // Replace with your main page
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        "Go to Main",
                        style: TextStyle(
                          fontSize: 16.0, // Text size
                          fontWeight: FontWeight.bold, // Make text bold
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 10,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill For Parking'),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Bill & Booking Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50, // Light green background
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              child: Text(
                "Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Time Picker
            TextFormField(
              controller: timeController,
              decoration: InputDecoration(
                labelText: "Select Time",
                hintText: "HH:MM:SS",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: _pickTime,
                ),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 20),
            const Text(
              "Upload Picture",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child:
                                Image.memory(_imageBytes!, fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Icon(Icons.add_a_photo,
                                size: 50, color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isButtonDisabled ? null : _savebillAndBooking,
                child: const Text("Submit Bill For parking"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
