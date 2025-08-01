import 'dart:async';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:parking1/homepage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class BuyTicket extends StatefulWidget {
  final String bookingId;

  const BuyTicket({
    super.key,
    required this.bookingId,
  });

  @override
  State<BuyTicket> createState() => _BuyTicketState();
}

class _BuyTicketState extends State<BuyTicket> {
  late Future<Map<String, dynamic>> _ticketFuture;
  Timer? _timer;
  int remainingSeconds = 60 * 60; // 30 minutes in seconds
  late String userName;
  late String numberplate;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _ticketFuture = fetchTicketData();
    _initializeNotifications();
    startTimer();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

// Function to fetch the userName from the users collection
  Future<String> getUserName(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc['username'] ?? 'Unknown'; // Return userName or 'Unknown'
      }
      return 'Unknown'; // In case the document doesn't exist
    } catch (e) {
      print("Error fetching userName: $e");
      return 'Unknown'; // Return 'Unknown' in case of error
    }
  }

  Future<String> getNumberPlate(String vehicleId) async {
    try {
      DocumentSnapshot vehicleDoc = await FirebaseFirestore.instance
          .collection('vehicles') // Adjust collection name if needed
          .doc(vehicleId)
          .get();

      if (vehicleDoc.exists) {
        return vehicleDoc['numberplate'] ??
            'Unknown'; // Return userName or 'Unknown'
      }
      return 'Unknown'; // In case the document doesn't exist
    } catch (e) {
      print("Error fetching userName: $e");
      return 'Unknown'; // Return 'Unknown' in case of error
    }
  }

  Future<Map<String, dynamic>> fetchTicketcar() async {
    DocumentSnapshot bookingSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .get();

    if (!bookingSnapshot.exists) {
      throw Exception("Booking not found");
    }

    var bookingData = bookingSnapshot.data() as Map<String, dynamic>;
    String userId = bookingData['userId'];
    String vehicleId = bookingData['vehicleId']; // Make sure vehicleId exists

    userName = await getUserName(userId);
    String numberplate = await getNumberPlate(vehicleId); // Fetch number plate

    return {
      'booking': bookingData,
    };
  }

  Future<Map<String, dynamic>> fetchTicketData() async {
    DocumentSnapshot bookingSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .get();

    if (!bookingSnapshot.exists) {
      throw Exception("Booking not found");
    }

    var bookingData = bookingSnapshot.data() as Map<String, dynamic>;
    String userId = bookingData['userId'];
    userName = await getUserName(userId);

    String vehicleId = bookingData['vehicleId'];
    numberplate = await getNumberPlate(vehicleId);

    String transactionId = bookingData['paymentId'] ?? '';
    var parkingStatus = bookingData['Status'] ?? 'pending';

    DocumentSnapshot paymentSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .doc(transactionId)
        .get();

    Map<String, dynamic> paymentData = paymentSnapshot.exists
        ? paymentSnapshot.data() as Map<String, dynamic>
        : {};

    int lastRemaining = bookingData['remainingSeconds'] ?? (60 * 60);
    Timestamp? lastUpdated = bookingData['lastUpdated'];

    if (lastUpdated != null) {
      int elapsed = DateTime.now().difference(lastUpdated.toDate()).inSeconds;
      remainingSeconds = (lastRemaining - elapsed).clamp(0, 60 * 60);
    } else {
      remainingSeconds = lastRemaining;
    }

    if (remainingSeconds > 0 && parkingStatus == 'pending') {
      startTimer();
    } else if (parkingStatus == 'check-in' || parkingStatus == 'check-out') {
      stopTimer();
    }

    FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        String newStatus = snapshot['Status'] ?? 'pending';

        if (newStatus == 'check-in' || newStatus == 'check-out') {
          stopTimer();
        } else if (newStatus == 'pending' && _timer == null) {
          startTimer();
        }
        setState(() {
          bookingData['Status'] = newStatus;
        });
      }
    });

    return {
      'booking': bookingData,
      'payment': paymentData,
    };
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });

        // ✅ Show local notification at 10 minutes remaining
        if (remainingSeconds == 600) {
          await flutterLocalNotificationsPlugin.show(
            1,
            '10 Minutes Left',
            'Your parking session will end in 10 minutes.',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'reminder_channel',
                'Reminder Notifications',
                channelDescription: 'Notifications for parking reminders',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
              ),
            ),
          );
        }

        // 🔁 Update Firestore every 5 seconds
        if (remainingSeconds % 1 == 0) {
          await FirebaseFirestore.instance
              .collection('bookings')
              .doc(widget.bookingId)
              .update({
            'remainingSeconds': remainingSeconds,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      } else {
        timer.cancel();
        await updateParkingStatusToCheckout();
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }

  Future<void> updateParkingStatusToCheckout() async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .update({'Status': 'Time-out'});

    // ✅ Show local notification
    await flutterLocalNotificationsPlugin.show(
      0,
      'Time Expired',
      'Your 60-minute parking session has ended.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'timeout_channel',
          'Timeout Notifications',
          channelDescription: 'Notifications for parking timeout',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );

    // ✅ Optional: Show dialog as well
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Time Expired"),
          content: const Text("Your 60-minute parking session has ended."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => Homepage()),
                  (route) => false,
                );
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> saveFcmToken(String userId) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': fcmToken,
      });
    }
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int sec = seconds % 60;
    return "$minutes:${sec.toString().padLeft(2, '0')}";
  }

  Future<void> _launchURL(String latitude, String longitude) async {
    try {
      final url =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not open the map';
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _ticketFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              }
              if (!snapshot.hasData) {
                return const Text("No booking found");
              }

              var bookingData = snapshot.data!['booking'];
              var paymentData = snapshot.data!['payment'];
              String bookingDate = bookingData['bookingDate'] ?? 'N/A';
              String locationName = bookingData['nameparking'] ?? 'N/A';
              String bookingTime = bookingData['bookingTime'] ?? 'N/A';
              String transactionId = bookingData['paymentId'] ?? 'N/A';
              String locationId = bookingData['locationId'] ?? 'N/A';
              String parkingStatus = bookingData['Status'] ?? 'N/A';
              String charplate = bookingData['charplate'] ?? 'N/A';
              String car = bookingData['vehicle'] ?? 'N/A';
              int amount = paymentData['amount'] ?? '0.00';
              GeoPoint location = bookingData['location'];
              double latitude = location.latitude;
              double longitude = location.longitude;

              String qrData =
                  "BookingID: ${widget.bookingId}\nUser: $userName\nDate: $bookingDate\nTime: $bookingTime\nPaymentID: $transactionId\nStatus: $parkingStatus\nAmount: $amount\nNumplate: $numberplate\nVehicle: $car\nlocationId:$locationId";

              // Modern front card with a gradient background and refined styling.
              Widget frontCard = Container(
                width: 350,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFF1F8E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_parking,
                            size: 40, color: Colors.black87),
                        SizedBox(width: 10),
                        Text(
                          "PARKING_TICKET".tr(),
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      bookingDate,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("From".tr(), style: TextStyle(fontSize: 16)),
                            Text(userName,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("Time".tr(), style: TextStyle(fontSize: 16)),
                            Text(bookingTime,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "location_display"
                          .tr(namedArgs: {"locationName": locationName}),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "paid_amount".tr(namedArgs: {
                        "amount": amount.toString()
                      }), // Ensure amount is a String
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "status_display"
                          .tr(namedArgs: {"parkingStatus": parkingStatus}),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "car_display".tr(namedArgs: {"car": car}),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4), // Add spacing
                    Text(
                      "plate_display"
                          .tr(namedArgs: {"numberplate": numberplate}),
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        "time_left_display".tr(namedArgs: {
                          "remainingTime": formatTime(remainingSeconds)
                        }),
                        style: const TextStyle(
                            fontSize: 20,
                            color: Colors.red,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _launchURL(latitude.toString(), longitude.toString()),
                      icon: const Icon(Icons.map),
                      label: Text("Navigate_to_Location").tr(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => Homepage()),
                          (route) =>
                              false, // This removes all previous routes from the stack
                        );
                      },
                      icon: const Icon(Icons.home),
                      label: Text("Main_Page".tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Tap to view QR code",
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ],
                ),
              );

              // Modern back card displaying the QR code.
              Widget backCard = Container(
                width: 350,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Tap to flip back",
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ],
                ),
              );

              return FlipCard(front: frontCard, back: backCard);
            },
          ),
        ),
      ),
    );
  }
}

/// A custom flip card widget that flips between the front and back sides.
class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;

  const FlipCard({Key? key, required this.front, required this.back})
      : super(key: key);

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  bool _showFrontSide = true;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_showFrontSide) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _showFrontSide = !_showFrontSide;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          double angle = _animation.value * 3.141592653589793;
          bool isFront = angle <= (3.141592653589793 / 2);
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFront
                ? widget.front
                : Transform(
                    transform: Matrix4.rotationY(3.141592653589793),
                    alignment: Alignment.center,
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}
