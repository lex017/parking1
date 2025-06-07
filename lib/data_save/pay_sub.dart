import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:parking1/chose/ownerMain.dart';
import 'package:parking1/homepage.dart';
import 'package:time_picker_spinner/time_picker_spinner.dart';

class PaySub extends StatefulWidget {
  final num? pricePerDay;
  final num? totalPrice;
  final String parkingId;

  final String name;

  final num? pricePerMonth;
  final int price;
  final int slots;
  final int months;
  final String packageType;

  const PaySub({
    super.key,
    required this.pricePerDay,
    required this.totalPrice,
    required this.parkingId,
    required this.name,
    this.pricePerMonth,
    required this.price,
    required this.slots,
    required this.months,
    required this.packageType,
  });

  @override
  State<PaySub> createState() => _PayPageState();
}

class _PayPageState extends State<PaySub> {
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isButtonDisabled = false;

  String imageBill = '';
  String locationId = '';
  int months = 0;
  String nameParking = '';
  String ownerId = '';
  String packageType = '';
  int price = 0;
  int pricePerDay = 0;
  String status = '';
  String tag = '';
  DateTime now = DateTime.now();

  final TextEditingController timeController = TextEditingController();

  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<String> generateLocationId() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('parking').get();
    int count = snapshot.docs.length;
    return "location${count + 1}";
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

  Future<void> fetchCategories() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('parking')
        .doc(widget.parkingId)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;

      setState(() {
        imageBill = data['imageBill'] ?? '';
        tag = data['tag'] ?? '';
        locationId = data['locationId'] ?? '';
        months = data['months'] ?? 0;
        nameParking = data['nameparking'] ?? '';
        ownerId = data['ownerId'] ?? '';
        packageType = data['packageType'] ?? '';
        price = data['price'] ?? 0;
        pricePerDay = data['pricePerDay'] ?? 0;
      });
    }
  }

  Future<void> _savebillAndBooking() async {
    if (_isButtonDisabled) return;

    setState(() {
      _isButtonDisabled = true;
    });

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in.")),
      );
      setState(() {
        _isButtonDisabled = false;
      });
      return;
    }

    if (timeController.text.isEmpty ||
        (_selectedImage == null && _imageBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fill all fields and upload an image.")),
      );
      setState(() {
        _isButtonDisabled = false;
      });
      return;
    }

    String? imageUrl = await _uploadImageToCloudinary();
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image upload failed.")),
      );
      setState(() {
        _isButtonDisabled = false;
      });
      return;
    }

    try {
      String newLocationId = await generateLocationId();
      String transactionId = "bill$newLocationId";

      // Save bill with status pending, no slot update here
      await FirebaseFirestore.instance
          .collection('parking_bill')
          .doc(transactionId)
          .set({
        'nameparking': nameParking,
        'ownerId': user.uid,
        'price': price,
        'pricePerDay': widget.pricePerDay,
        'totalPrice': widget.totalPrice,
        'car_slot': widget.slots, // keep additionalSlots for reference
        'imageBill': imageUrl,
        'status': "pending",
        'package': "Renew",
        'months': months,
        'date': DateFormat('d/M/yyyy').format(DateTime.now()),
        'time': timeController,
        'packageType': packageType,
        'tag': tag,
        'locationId': widget.parkingId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Bill submitted. Waiting for verification...")),
      );
      listenForBillStatus(transactionId);

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
                  docSnapshot.data()?['status'] == "renew") {
                isVerified = true; // persist success

                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.of(context, rootNavigator: true).pop();
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

  void listenForBillStatus(String transactionId) {
    FirebaseFirestore.instance
        .collection('parking_bill')
        .doc(transactionId)
        .snapshots()
        .listen((docSnapshot) async {
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        if (data['status'] == 'renew') {
          String locationId = data['locationId'];
          int additionalSlots = data['car_slot'] ?? 0;
          String packageType = data['packageType'] ?? "1 Month";

          // Extract number of months from packageType (e.g., "1 Month" → 1)
          int monthsToAdd = int.tryParse(packageType.split(" ")[0]) ?? 1;
          Timestamp now = Timestamp.now();

          final parkingRef =
              FirebaseFirestore.instance.collection('parking').doc(locationId);
          final parkingSnapshot = await parkingRef.get();

          if (parkingSnapshot.exists) {
            Map<String, dynamic> parkingData = parkingSnapshot.data()!;
            int currentSlots = parkingData['car_slot'] ?? 0;
            int currentMonths = parkingData['months'] ?? 0;
            int updatedSlots = currentSlots + additionalSlots;
            int updatedMonths = currentMonths + monthsToAdd;

            await parkingRef.update({
              'car_slot': updatedSlots,
              'months': updatedMonths,
              'packageMonths': monthsToAdd,
              'packageStartDate': now,
              'packageType': packageType,
              'startdate': now,
            });

            print("✅ Parking renewed:");
            print("• Slots: $currentSlots + $additionalSlots = $updatedSlots");
            print("• Months: $currentMonths + $monthsToAdd = $updatedMonths");
            print("• packageStartDate and startdate updated");
          } else {
            // If parking doc doesn't exist, create it
            await parkingRef.set({
              'car_slot': additionalSlots,
              'months': monthsToAdd,
              'packageMonths': monthsToAdd,
              'packageStartDate': now,
              'packageType': packageType,
              'startdate': now,
              'status': "active",
            });
            print("ℹ️ Created new parking document for renewal.");
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pay for Additional Slots"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Price per day: ${widget.pricePerDay?.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')} Kip"),
            const SizedBox(height: 8),
            Text(
                "Total price: ${widget.totalPrice?.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')} Kip"),
            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50, // Light green background
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              child: Text(
                "Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Time Picker
            TextFormField(
              controller: timeController,
              decoration: InputDecoration(
                labelText: "Select Time",
                hintText: "HH:MM AM/PM",
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
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                  color: Colors.grey.shade200,
                ),
                child: Center(
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : (_imageBytes != null
                          ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.camera_alt, size: 40),
                                SizedBox(height: 8),
                                Text("Tap to upload payment proof"),
                              ],
                            )),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isButtonDisabled ? null : _savebillAndBooking,
                child: _isButtonDisabled
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Submit Bill"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
