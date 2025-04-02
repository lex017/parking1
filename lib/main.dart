import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:parking1/loginandregis/loginPage.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

// Global ValueNotifier for theme mode
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

Future<void> loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final themeModeIndex = prefs.getInt('themeMode') ?? 0;
  switch (themeModeIndex) {
    case 1:
      themeModeNotifier.value = ThemeMode.light;
      break;
    case 2:
      themeModeNotifier.value = ThemeMode.dark;
      break;
    default:
      themeModeNotifier.value = ThemeMode.system;
      break;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await loadThemeMode();

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
    _checkInternetConnectivity();
  }

  void _initializeFCM() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _firebaseMessaging.getToken().then((token) {
        print("FCM Token: $token");
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          _showNotificationDialog(message.notification!);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (message.notification != null) {
          print("Notification clicked! Title: ${message.notification!.title}");
        }
      });
    } else {
      print("User declined or has not accepted permission");
    }
  }

  void _checkInternetConnectivity() async {
    // Delaying the internet check until the widget is fully loaded
    await Future.delayed(Duration(milliseconds: 100));

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showNoInternetDialog();
    }

    Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        _showNoInternetDialog();
      }
    });
  }

  void _showNoInternetDialog() {
    // Use the mounted check to ensure the widget is still in the widget tree
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("No Internet Connection"),
        content: const Text("Please check your internet connection and try again."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(RemoteNotification notification) {
    // Ensuring the dialog is shown after the widget is fully mounted
    if (!mounted) return;

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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentTheme, _) {
        return MaterialApp(
          title: 'Parking App',
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white, 
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 22.0,
              ),
              iconTheme: IconThemeData(
                color: Colors.black,
                size: 33.0,
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.white, 
              selectedItemColor: Colors.blue, 
              unselectedItemColor: Colors.grey, 
              selectedLabelStyle: TextStyle(fontSize: 16), 
              unselectedLabelStyle: TextStyle(fontSize: 14),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black87, 
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black87, 
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 22.0,
              ),
              iconTheme: IconThemeData(
                color: Colors.white,
                size: 33.0,
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.black87, 
              selectedItemColor: Colors.blueAccent, 
              unselectedItemColor: Colors.grey, 
              selectedLabelStyle: TextStyle(fontSize: 16),
              unselectedLabelStyle: TextStyle(fontSize: 14),
            ),
          ),
          themeMode: currentTheme, 
          home: const loginPage(), 
        );
      },
    );
  }
}