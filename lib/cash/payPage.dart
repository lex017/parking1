import 'dart:typed_data';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:lottie/lottie.dart';
import 'package:parking1/bottombar/chatPage.dart';

import 'package:parking1/data_save/buyticket.dart';
import 'package:parking1/homepage.dart';
import 'package:time_picker_spinner/time_picker_spinner.dart';

class PayPage extends StatefulWidget {
  final String documentId;
  final String selectedCar;
  final String selectedVehicleId;
  final String selectedCharplate;
  final String selectedNumberplate;
  final String selectedColor;
  final String selectedProvince;
  final String selectedTypeplate;
  final int pricePerHour;

  const PayPage(
      {super.key,
      required this.documentId,
      required this.selectedCar,
      required this.selectedVehicleId,
      required this.pricePerHour,
      required this.selectedCharplate,
      required this.selectedNumberplate,
      required this.selectedColor,
      required this.selectedProvince,
      required this.selectedTypeplate});

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  DateTime now = DateTime.now();

  final TextEditingController amountController = TextEditingController();
  final TextEditingController accountController = TextEditingController();

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
    listenForPaymentStatus(bookingId, context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        checkAndUpdateTimeoutBookings(user.uid);
      }
    });
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
    int selectedHour = DateTime.now().hour;
    int selectedMinute = DateTime.now().minute;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 380,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Icon(Icons.access_time_rounded,
                        color: Colors.blueAccent, size: 40),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'SelectTime'.tr(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildPicker(
                            count: 24,
                            selected: selectedHour,
                            onChanged: (v) =>
                                setModalState(() => selectedHour = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildPicker(
                            count: 60,
                            selected: selectedMinute,
                            onChanged: (v) =>
                                setModalState(() => selectedMinute = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                      ),
                      label: Text(
                        'ConfirmTime'.tr(),
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final formatted =
                            '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
                        setState(() => timeController.text = formatted);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPicker({
    required int count,
    required int selected,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      color: Colors
          .white, // Set the background color to white or any color you prefer
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        perspective: 0.002,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        controller: FixedExtentScrollController(initialItem: selected),
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            return Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: index == selected ? Colors.blue : Colors.black87,
                ),
              ),
            );
          },
          childCount: count,
        ),
      ),
    );
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
      final String locationId = widget.documentId;

      // Save a notification to Firestore with locationId
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': '🔔 New Booking',
        'body':
            'New booking needs verification for transaction ID: $transactionId',
        'locationId': locationId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("Notification sent with locationId: $locationId");
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

      String transactionId = "payment${DateTime.now().millisecondsSinceEpoch}";
      String bookingId = "bookings${DateTime.now().millisecondsSinceEpoch}";

      String username = "Unknown User";
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
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
                    isVerified ? "Payment Successful" : "Payment_Verification".tr(),
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
                            : "waiting_for_payment_verification".tr(),
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isVerified
                            ? "Thank you for your payment."
                            : "please_do_not_close_the_app".tr(),
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
                          child: Text(
                            "Go_to_Main".tr(),
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
      DateTime now = DateTime.now();
      DateTime timeout = now.add(const Duration(hours: 1));
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(transactionId)
          .set({
        "userId": user.uid,
        "userName": username,
        "amount": widget.pricePerHour,
        "date": DateFormat('d/M/yyyy').format(DateTime.now()),
        "time": timeController.text,
        "bookingId": bookingId,
        "vechicle": widget.selectedCar,
        "vehicleId": widget.selectedVehicleId,
        "charplate": widget.selectedCharplate,
        "numberplate": widget.selectedNumberplate,
        "color": widget.selectedColor,
        "province": widget.selectedProvince,
        "typeplate": widget.selectedTypeplate,
        "imageBill": imageUrl,
        "locationId": locationId,
        "status": "pending",
        "timestamp": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .set({
        "userId": user.uid,
        "userName": username,
        "bookingDate": DateFormat('d/M/yyyy').format(DateTime.now()),
        "bookingTime": timeController.text,
        "paymentId": transactionId,
        "locationId": locationId,
        "nameparking": nameLocation,
        "location": location,
        "vehicle": widget.selectedCar,
        "vehicleId": widget.selectedVehicleId,
        "charplate": widget.selectedCharplate,
        "numberplate": widget.selectedNumberplate,
        "color": widget.selectedColor,
        "province": widget.selectedProvince,
        "typeplate": widget.selectedTypeplate,
        "paymentStatus": "pending",
        "Status": "pending",
        'timeout': Timestamp.fromDate(timeout),
        "timestamp": FieldValue.serverTimestamp(),
      });

      _sendNotification(transactionId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Payment submitted. Waiting for verification.")),
      );

      listenForPaymentStatus(bookingId, context);
    } catch (e) {
      print("Unexpected error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Something went wrong. Please try again.")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> checkAndUpdateTimeoutBookings(String userId) async {
    final now = Timestamp.now();
    print("Now: $now | userId: $userId");

    final query = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('Status', isEqualTo: 'pending')
        .where('timeout', isLessThanOrEqualTo: now)
        .get();

    print("Found ${query.docs.length} expired bookings");

    for (var doc in query.docs) {
      await doc.reference.update({'Status': 'time-out'});
      showLocalNotification(
        title: 'Booking Expired',
        body: 'การจองของคุณหมดเวลาแล้ว',
      );
    }
  }

  void showLocalNotification({required String title, required String body}) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'booking_timeout_channel',
      'Booking Timeout',
      channelDescription: 'Notification when booking is expired',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
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

      if (status == "success" &&
          !shownBookingNotifications.contains(bookingId)) {
        shownBookingNotifications
            .add(bookingId); // prevent multiple notifications

        await showPaymentSuccessNotification();
        Navigator.of(context, rootNavigator: true).pop();

        await Future.delayed(const Duration(seconds: 2));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BuyTicket(
              bookingId: bookingId,
            ),
          ),
        );
      } else if (status == "reject") {
        await showPaymentRejectNotification(); // <-- ADD THIS LINE

        Navigator.of(context, rootNavigator: true).pop();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Payment Rejected"),
            content: const Text(
                "Your payment was rejected.\nPlease contact the admin."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        bookingId: bookingId,
                        initialMessage:
                            'My bill was rejected. Please help me.\nTransaction ID: $bookingId',
                      ),
                    ),
                    (route) => false,
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
          title: Text('Payment&Booking'.tr()),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Card
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade100, Colors.green.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/images/kip.png',
                        width: 24,
                        height: 24,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'amountPerUnit'
                          .tr(args: [widget.pricePerHour.toString()]),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Date Card
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade100, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, color: Colors.blue, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'currentDate'.tr(args: [
                        DateFormat('yyyy-MM-dd').format(DateTime.now())
                      ]),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Time Picker
              TextFormField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: "SelectTime".tr(),
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
              const SizedBox(height: 30),

              // Upload Picture Title
              Text(
                "UploadPicture".tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Image Upload Container
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : Center(
                              child: Text(
                                "Taptouploadimage".tr(),
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 40),

              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePaymentAndBooking,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          "Pay_Now".tr(),
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ));
  }
}
