import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:parking1/data_save/buyticket.dart';
import 'package:parking1/loginandregis/loginPage.dart';

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  if (message.notification != null) {
    print("Title: ${message.notification!.title}");
    print("Body: ${message.notification!.body}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const ParkingApp());
}

class ParkingApp extends StatefulWidget {
  const ParkingApp({super.key});

  @override
  State<ParkingApp> createState() => _ParkingAppState();
}

class _ParkingAppState extends State<ParkingApp> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  void _initializeFCM() async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted permission");

      // Get FCM token for the device
      _firebaseMessaging.getToken().then((token) {
        print("FCM Token: $token");
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          _showNotificationDialog(message.notification!);
        }
      });

      // Handle notification click when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (message.notification != null) {
          print("Notification clicked! Title: ${message.notification!.title}");
        }
      });
    } else {
      print("User declined or has not accepted permission");
    }
  }

  void _showNotificationDialog(RemoteNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title ?? "No Title"),
        content: Text(notification.body ?? "No Body"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 22.0,
          ),
          iconTheme: IconThemeData(color: Colors.black, size: 33.0),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedLabelStyle: TextStyle(fontSize: 25, color: Colors.white),
          unselectedLabelStyle: TextStyle(fontSize: 14, color: Colors.white),
        ),
      ),
      home: const loginPage(),
    );
  }
}
