import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:parking1/loginandregis/loginPage.dart';
import 'package:parking1/menu/GlobalTimerBanner%20.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';

// ตัวแปร global สำหรับ local notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background message handler (top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'background_channel',
      'Background Notifications',
      channelDescription: 'Notifications shown when app is in background',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
    );
  }

  print("📩 Background Message: ${message.messageId}");
}

/// Global ValueNotifier สำหรับ theme mode
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

/// โหลด theme mode จาก SharedPreferences
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
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp();

  // ตั้งค่า flutter_local_notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      // กรณีต้องการ handle เมื่อผู้ใช้แตะ notification
      print("Notification clicked");
    },
  );

  // ตั้งค่ารับข้อความ background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await loadThemeMode();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('lo'),
        Locale('zh'),
        Locale('ko'),
        Locale('vi'),
        Locale('th'),
      ],
      path: 'assets/lang',
      fallbackLocale: const Locale('en'),
       child: ParkingApp(),
    ),
  );
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
        print("📱 FCM Token: $token");
        // TODO: บันทึก token ที่ต้องการ
      });

      // เมื่อแอปอยู่ foreground รับข้อความและแสดง local notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          const AndroidNotificationDetails androidDetails =
              AndroidNotificationDetails(
            'foreground_channel',
            'Foreground Notifications',
            channelDescription: 'Notifications shown when app is in foreground',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          );

          const NotificationDetails platformDetails =
              NotificationDetails(android: androidDetails);

          await flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            platformDetails,
          );

          // หรือถ้าอยากแสดง Dialog แทนให้ใช้ _showNotificationDialog()
        }
      });

      // เมื่อผู้ใช้แตะ notification ที่อยู่ background หรือ terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("🖱️ Notification clicked: ${message.notification?.title}");
        // TODO: นำทางไปหน้าที่ต้องการ
      });
    } else {
      print("❌ Permission for notifications declined");
    }
  }

  void _checkInternetConnectivity() async {
    await Future.delayed(const Duration(milliseconds: 100));
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentTheme, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Parking App',
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 22.0),
              iconTheme: IconThemeData(color: Colors.black, size: 33.0),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
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
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 22.0),
              iconTheme: IconThemeData(color: Colors.white, size: 33.0),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.black87,
              selectedItemColor: Colors.blueAccent,
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: TextStyle(fontSize: 16),
              unselectedLabelStyle: TextStyle(fontSize: 14),
            ),
          ),
          themeMode: currentTheme,
          home: GlobalTimerBanner(child: const loginPage()), // แก้เป็นหน้าหลักของคุณ
        );
      },
    );
  }
}
