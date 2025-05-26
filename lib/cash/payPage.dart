
import 'dart:typed_data';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:lottie/lottie.dart';
import 'package:parking1/bottombar/chatPage.dart';


import 'package:parking1/data_save/buyticket.dart';
import 'package:parking1/homepage.dart';

class PayPage extends StatefulWidget {
  final String documentId;
  final String selectedCar;
  final String selectedVehicleId;
  final int pricePerHour;

  const PayPage(
      {super.key,
      required this.documentId,
      required this.selectedCar,
      required this.selectedVehicleId,
      required this.pricePerHour});

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController accountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    String bookingId = "bookings${DateTime.now().millisecondsSinceEpoch}";
    listenForPaymentStatus(bookingId,context);
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
   void _initializeNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);
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
      FirebaseAuth auth = FirebaseAuth.instance;
      String? uid = auth.currentUser?.uid;

      if (uid == null) {
        print("No user logged in");
        return;
      }

      // Get the employee's locationId from Firestore
      DocumentSnapshot empDoc = await FirebaseFirestore.instance
          .collection('employees')
          .doc(uid)
          .get();

      if (!empDoc.exists) {
        print("Employee document not found");
        return;
      }

      String? locationId = empDoc.get('locationId');

      // Save the notification with locationId
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'New Payment Verification',
        'body':
            'Payment for transaction ID: $transactionId requires verification.',
        'locationId': locationId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("Notification saved with locationId: $locationId");
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  Future<void> _savePaymentAndBooking() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in.")),
      );
      return;
    }

    if (dateController.text.isEmpty ||
        timeController.text.isEmpty ||
        (_selectedImage == null && _imageBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and upload an image.")),
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

    String username = "Unknown User";
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        username = userData['username'] ?? "Unknown User";
      }
    } catch (e) {
      print("Error fetching username: $e");
    }

    String locationId = widget.documentId;
    String nameLocation = "";
    GeoPoint location = const GeoPoint(0, 0);

    try {
      var locationSnapshot = await FirebaseFirestore.instance
          .collection('parking')
          .doc(locationId)
          .get();

      if (locationSnapshot.exists) {
        var locationData = locationSnapshot.data() as Map<String, dynamic>;
        nameLocation = locationData['nameparking'] ?? "Unknown Location";

        if (locationData['location'] is GeoPoint) {
          location = locationData['location'];
        } else {
          print("Error: Invalid location format in Firestore.");
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No location found.")),
        );
        return;
      }
    } catch (e) {
      print("Error fetching location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to retrieve location.")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isVerified = false;

            FirebaseFirestore.instance
                .collection('payments')
                .doc(transactionId)
                .snapshots()
                .listen((docSnapshot) {
              if (docSnapshot.exists &&
                  docSnapshot.data()?['paymentStatus'] == "success") {
                setState(() {
                  isVerified = true;
                });
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              title: Center(
                child: Text(
                  isVerified ? "Payment Successful" : "Payment Verification",
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
                          ? "Payment Verified Successfully!"
                          : "Waiting for payment verification...",
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isVerified
                          ? "Thank you for your payment."
                          : "Please do not close the app.",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 20.0),
                          elevation: 5,
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Homepage(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          "Go to Main",
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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

    await FirebaseFirestore.instance.collection('payments').doc(transactionId).set({
      "userId": user.uid,
      "userName": username,
      "amount": widget.pricePerHour,
      "date": dateController.text,
      "time": timeController.text,
      "bookingId": bookingId,
      "vechicle": widget.selectedCar,
      "imageBill": imageUrl,
      "locationId": locationId,
      "status": "pending",
      "timestamp": FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).set({
      "userId": user.uid,
      "userName": username,
      "bookingDate": dateController.text,
      "bookingTime": timeController.text,
      "paymentId": transactionId,
      "locationId": locationId,
      "nameparking": nameLocation,
      "location": location,
      "vehicle": widget.selectedCar,
      "vehicleId": widget.selectedVehicleId,
      "paymentStatus": "pending",
      "Status": "pending",
      "timestamp": FieldValue.serverTimestamp(),
    });

    _sendNotification(transactionId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment submitted. Waiting for verification.")),
    );

    listenForPaymentStatus(bookingId, context);
  } catch (e) {
    print("Unexpected error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Something went wrong. Please try again.")),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  Future<int> countCheckedInTickets() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    QuerySnapshot ticketSnapshot = await FirebaseFirestore.instance
        .collection(
            'bookings') // Make sure this matches your Firestore collection name
        .where('userId', isEqualTo: userId)
        .where('Status', isEqualTo: 'check-in') // Filter only "check-in" status
        .get();

    return ticketSnapshot.docs.length; // Return the count of filtered tickets
  }
  final Set<String> shownBookingNotifications = {};
  Future<void> showPaymentSuccessNotification() async {
  const androidDetails = AndroidNotificationDetails(
    'payment_channel',
    'Payment Notifications',
    channelDescription: 'Notifies when a payment is successful',
    importance: Importance.max,
    priority: Priority.high,
  );
  

  const notificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Payment Successful',
    'Your booking payment was successful! ✅',
    notificationDetails,
  );
}
 Future<void> showPaymentRejectNotification() async {
  const androidDetails = AndroidNotificationDetails(
    'payment_channel',
    'Payment Notifications',
    channelDescription: 'Notifies when a payment is Reject',
    importance: Importance.max,
    priority: Priority.high,
  );
  

  const notificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Payment Successful',
    'Your booking payment was Reject! ⚠️',
    notificationDetails,
  );
}



void listenForPaymentStatus(String bookingId, BuildContext context) {
  FirebaseFirestore.instance
      .collection('bookings')
      .doc(bookingId)
      .snapshots()
      .listen((snapshot) async {
    if (!snapshot.exists) return;

    final data = snapshot.data();
    final status = data?['paymentStatus'];

    if (status == "success" && !shownBookingNotifications.contains(bookingId)) {
      shownBookingNotifications.add(bookingId); // prevent multiple notifications

      await showPaymentSuccessNotification();
      Navigator.of(context, rootNavigator: true).pop();

      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BuyTicket(bookingId: bookingId),
        ),
      );
    } else if (status == "reject") {
      await showPaymentRejectNotification(); // <-- ADD THIS LINE

      Navigator.of(context, rootNavigator: true).pop();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Payment Rejected"),
          content: const Text("Your payment was rejected.\nPlease contact the admin."),
          actions: [
          TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(bookingId: bookingId),
              ),
            );
          },
          child: const Text("Go to Admin"),
            ),
          ],
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
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Payment & Booking Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50, // Light green background
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              child: Text(
                "Amount: ${widget.pricePerHour}",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                onPressed: _isLoading
                    ? null
                    : _savePaymentAndBooking, // Disable when loading
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black, // Match text color
                          strokeWidth: 3,
                        ),
                      )
                    : const Text("Pay Now",
                        style: TextStyle(fontSize: 18, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
