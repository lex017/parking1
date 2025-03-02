import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:parking1/cash/receip.dart';
import 'package:parking1/data_save/buyticket.dart';

class PayPage extends StatefulWidget {
  final int packageHours;

  const PayPage({super.key, required this.packageHours});

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController amountController = TextEditingController();
  final TextEditingController accountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";
  @override
void initState() {
  super.initState();
  // Listen for payment status with a placeholder transaction ID
  // You should pass the correct transactionId here
  String bookingId = "bookings${DateTime.now().millisecondsSinceEpoch}";
  listenForPaymentStatus(bookingId);
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

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      String formattedDate =
          "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      setState(() {
        dateController.text = formattedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      String formattedTime = pickedTime.format(context);
      setState(() {
        timeController.text = formattedTime;
      });
    }
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

  Future<void> _sendNotification(String transactionId) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'New Payment Verification',
          'body':
              'Payment for transaction ID: $transactionId requires verification.',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  Future<void> _savePaymentAndBooking() async {
    if (amountController.text.isEmpty ||
        dateController.text.isEmpty ||
        timeController.text.isEmpty ||
        nameController.text.isEmpty ||
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

    String transactionId = "payment${DateTime.now().millisecondsSinceEpoch}";
    String bookingId = "bookings${DateTime.now().millisecondsSinceEpoch}";

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Waiting for payment verification..."),
          ],
        ),
      ),
    );

    // Save payment and booking data
    FirebaseFirestore.instance.collection('payments').doc(transactionId).set({
      "amount": amountController.text,
      "date": dateController.text,
      "time": timeController.text,
      "name": nameController.text,
      "imageBill": imageUrl,
      "paymentStatus": "pending",
      "timestamp": FieldValue.serverTimestamp(),
    });

    FirebaseFirestore.instance.collection('bookings').doc(bookingId).set({
      "userName": nameController.text,
      "bookingDate": dateController.text,
      "bookingTime": timeController.text,
      "paymentId": transactionId,
      "paymentStatus": "pending",
      "parkingStatus": "pending",
      "timestamp": FieldValue.serverTimestamp(),
    }).then((_) {
      _sendNotification(transactionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Payment submitted. Waiting for verification.")),
      );
    }).catchError((error) {
      print("Error saving booking: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save booking. Try again.")),
      );
    });

    // Listen for payment status update
    listenForPaymentStatus(bookingId);
  }

  void listenForPaymentStatus(String bookingId) {
    FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data()?['paymentStatus'] == "success") {
        // Close the loading dialog
        Navigator.of(context, rootNavigator: true)
            .pop(); // Closes the loading dialog

        // Navigate to BuyTicketPage only if payment is successful
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BuyTicket(
              bookingId: bookingId, // Pass transaction ID
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment & Booking'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Payment & Booking Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: "Amount",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: dateController,
              decoration: InputDecoration(
                labelText: "Select Date",
                hintText: "DD/MM/YY",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: timeController,
              decoration: InputDecoration(
                labelText: "Select Time",
                hintText: "HH:MM AM/PM",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: _pickTime,
                ),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Name",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Upload Picture",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                            child: Text("Tap to upload",
                                style: TextStyle(color: Colors.grey)),
                          ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: _savePaymentAndBooking,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.white,
                ),
                child: const Text("Pay Now",
                    style: TextStyle(fontSize: 18, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
