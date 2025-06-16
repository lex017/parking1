import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parking1/chose/detail_ownner.dart';
import 'package:parking1/chose/mapapi.dart';
import 'package:parking1/data_save/btnadd_parking.dart';
import 'package:parking1/data_save/subscription_package.dart';
import 'package:parking1/detailownner/detail_booking.dart';
import 'package:parking1/detailownner/detail_money.dart';
import 'package:parking1/map_api/btnlocation.dart';
import 'package:parking1/map_api/map_api.dart';
import 'package:parking1/menu/Help.dart';
import 'package:parking1/menu/emp_register.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class ownerMain extends StatefulWidget {
  const ownerMain({super.key});

  @override
  State<ownerMain> createState() => _OwnerMainState();
}

class _OwnerMainState extends State<ownerMain> {
  final auth = FirebaseAuth.instance;
  late Stream<String> _realTimeDateStream;
  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _realTimeDateStream = _getRealTimeDate();
  }

  Stream<String> _getRealTimeDate() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      DateTime now = DateTime.now();
      String formattedDate =
          "${now.day}-${now.month}-${now.year} ${now.hour}:${now.minute}";
      yield formattedDate;
    }
  }

  Future<void> _launchLocation(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> updateParkingStatus(String parkingId) async {
    try {
      tz.initializeTimeZones();

      final docRef =
          FirebaseFirestore.instance.collection('parking').doc(parkingId);
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data()!;
        final openTimeStr = data['openTime'];
        final closeTimeStr = data['closeTime'];
        final timezoneStr = data['timezone'] ?? 'Asia/Bangkok';

        final location = tz.getLocation(timezoneStr);
        final now = tz.TZDateTime.now(location);

        final openParts = openTimeStr.split(":").map(int.parse).toList();
        final closeParts = closeTimeStr.split(":").map(int.parse).toList();

        final openTime = tz.TZDateTime(
            location, now.year, now.month, now.day, openParts[0], openParts[1]);
        var closeTime = tz.TZDateTime(location, now.year, now.month, now.day,
            closeParts[0], closeParts[1]);

        // If closeTime is before openTime, assume it closes the next day
        if (closeTime.isBefore(openTime)) {
          closeTime = closeTime.add(const Duration(days: 1));
        }

        final isOpen = now.isAfter(openTime) && now.isBefore(closeTime);
        final newStatus = isOpen ? "Online" : "Offline";
        final currentStatus = data['status'];

        if (currentStatus != newStatus) {
          await docRef.update({'status': newStatus});
          print("Status updated to: $newStatus");
        } else {
          print("Status remains unchanged: $newStatus");
        }
      } else {
        print("Parking document not found");
      }
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  void toggleStatus(String userId, String currentStatus) async {
    String newStatus = currentStatus == "Online" ? "Offline" : "Online";
    final firestore = FirebaseFirestore.instance;

    // 1. Get the Owner document by userId
    final ownerSnapshot = await firestore
        .collection('Owner')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (ownerSnapshot.docs.isEmpty) {
      print("❌ No Owner found with userId: $userId");
      return;
    }

    final ownerDoc = ownerSnapshot.docs.first;
    final ownerDocId = ownerDoc.id;

    // 2. Update Owner status
    await firestore
        .collection('Owner')
        .doc(ownerDocId)
        .update({'status': newStatus});
    print("✅ Owner status updated");

    // 3. Update all parking documents with matching ownerId (userId)
    final parkingSnapshot = await firestore
        .collection('parking')
        .where('ownerId', isEqualTo: userId)
        .get();

    print("Found ${parkingSnapshot.docs.length} parking documents");

    for (var doc in parkingSnapshot.docs) {
      await doc.reference.update({'status': newStatus});
      print("✅ Updated parking ${doc.id} to $newStatus");
    }
  }

  Widget ticketWidget({
    required String fullName,
    required String dateOfBirth,
    required String age,
    required String status,
    required String email,
    required String idCard,
    required VoidCallback onToggle,
    required String profileImageUrl,
  }) {
    return LayoutBuilder(builder: (context, constraints) {
      final screenWidth = MediaQuery.of(context).size.width;

      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.blueAccent,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(18.0),
          ),
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Profile and Name
              Row(
                children: [
                  CircleAvatar(
                    radius: screenWidth * 0.08,
                    backgroundColor: Colors.grey[300],
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.08),
                      child: Image.network(
                        profileImageUrl,
                        width: screenWidth * 0.16,
                        height: screenWidth * 0.16,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person,
                              size: 30, color: Colors.grey);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      fullName,
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// Status and Email
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      "Email: $email",
                      style: TextStyle(fontSize: screenWidth * 0.035),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    "Status: $status",
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: status.toLowerCase() == 'online'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              const Divider(),

              /// Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'status'.tr(),
                    style: TextStyle(fontSize: screenWidth * 0.037),
                  ),
                  Row(
                    children: [
                      Text(
                        status == 'online'.tr()
                            ? 'gooffline'.tr()
                            : 'goonline'.tr(),
                        style: TextStyle(fontSize: screenWidth * 0.035),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: status.toLowerCase() == 'online',
                        onChanged: (value) => onToggle(),
                        activeColor: Colors.green,
                        activeTrackColor: Colors.lightGreenAccent,
                        inactiveThumbColor: Colors.red,
                        inactiveTrackColor: Colors.redAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget nameProfile() {
    final currentUser = auth.currentUser;

    if (currentUser == null || currentUser.email == null) {
      return const Center(
        child: Text('User not logged in',
            style: TextStyle(fontSize: 18, color: Colors.red)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Owner')
          .where('email', isEqualTo: currentUser.email)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Error loading profile',
                style: TextStyle(fontSize: 18, color: Colors.red)),
          );
        } else {
          final userDoc = snapshot.data!.docs.first;
          final userData = userDoc.data() as Map<String, dynamic>;

          final fname = userData['fname'] ?? 'Guest';
          final lname = userData['lname'] ?? '';
          final fullName = '$fname $lname';
          final email = userData['email'] ?? 'N/A';
          final dateOfBirth = userData['Dateofbirth'] ?? 'N/A';
          final age = userData['age'] ?? 'N/A';
          final idCard = userData['idcard'] ?? 'N/A';
          final profileImageUrl = userData['profile_image_url'] ?? '';
          final status = userData['status'] ?? 'Offline';

          return ticketWidget(
            fullName: fullName,
            dateOfBirth: dateOfBirth,
            age: age,
            status: status,
            email: email,
            idCard: idCard,
            onToggle: () => toggleStatus(userData['userId'], status),
            profileImageUrl: profileImageUrl,
          );
        }
      },
    );
  }

  Future<String?> _uploadImageToCloudinary() async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset;

      if (_imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', _imageBytes!,
              filename: 'image.jpg'),
        );
      } else if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', _selectedImage!.path),
        );
      } else {
        return null;
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final decodedData = jsonDecode(responseData);
        return decodedData['secure_url'];
      } else {
        print("Upload failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _addLocationWithImage(String name, String address,
      String description, int price, int carSlot) async {
    final String? imageUrl = await _uploadImageToCloudinary();

    if (imageUrl != null) {
      await FirebaseFirestore.instance.collection('parking').add({
        'nameparking': name,
        'address': address,
        'description': description,
        'price': price,
        'car_slot': carSlot,
        'imageUrl': imageUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location added successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image upload failed')),
      );
    }
  }

  Widget DashboardButton({
    required String iconPath,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.blueAccent,
              width: 1.0,
            ),
          ),
          margin: EdgeInsets.zero,
          child: Container(
            width: 140,
            height: 140,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  iconPath,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                const SizedBox(height: 18),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buttonthree(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceEvenly, // จัดให้ปุ่มกระจายตัวเท่าๆ กัน
        children: [
          Expanded(
            child: DashboardButton(
              iconPath: 'assets/images/income.png',
              label: 'income'.tr(),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => DetailMoney()),
                );
              },
            ),
          ),
          SizedBox(width: 15), // เพิ่มระยะห่าง
          Expanded(
            child: DashboardButton(
              iconPath: 'assets/images/ticket.png',
              label: 'history'.tr(),
              onPressed: () {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => DetailBooking(userId: userId)),
                  );
                } else {
                  // แสดง error หรือแจ้งเตือน
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User not logged in')),
                  );
                }
              },
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: DashboardButton(
              iconPath: 'assets/images/question.png',
              label: 'help'.tr(),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => Help()),
                );
              },
            ),
          ),
        ],
      ),
    );
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

  Widget parkLocation() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String ownerId = currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('parking')
          .where('ownerId', isEqualTo: ownerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text('Error loading locations',
                style: TextStyle(fontSize: 18, color: Colors.red)),
          );
        } else if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No parking locations available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        } else {
          final locations = snapshot.data!.docs;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final locationData =
                  locations[index].data() as Map<String, dynamic>;
              final docId = locations[index].id;

              final locationName =
                  locationData['nameparking'] ?? 'Unknown Location';
              final carSlot = locationData['car_slot'] ?? 'Unknown';
              final imageUrl = locationData['imageUrl'] ?? '';
              final pricePerMonth = locationData['pricePerMonth'] ?? '';
              final price = locationData['price'] ?? '';
              final status = locationData['status'] ?? "Offline";

              final startDate =
                  (locationData['packageStartDate'] as Timestamp?)?.toDate();
              final months = locationData['packageMonths'] ?? 1;
              final expiryDate = startDate != null
                  ? addMonths(startDate, months)
                  : DateTime.now();
              final isExpired = DateTime.now().isAfter(expiryDate);

              return GestureDetector(
                onTap: isExpired
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                DetailOwner(documentId: docId),
                          ),
                        );
                      },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16.0)),
                            child: Image.network(
                              imageUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                      child: Text("Failed to load image")),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Parking Location ${index + 1}",
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: status == "Online",
                                    onChanged: isExpired
                                        ? null
                                        : (value) {
                                            toggleStatusp(docId, status);
                                          },
                                    activeColor: Colors.green,
                                    inactiveThumbColor: Colors.red,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Location: $locationName",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const Divider(),
                              Text(
                                isExpired
                                    ? "Subscription: Expired"
                                    : "Subscription: Active",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isExpired ? Colors.red : Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Status: $status",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: status == "Online"
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (!isExpired && status == "Online")
                                StreamBuilder<int>(
                                  stream: FirebaseFirestore.instance
                                      .collection('bookings')
                                      .where('locationId', isEqualTo: docId)
                                      .where('Status',
                                          whereIn: ['check-in', 'pending'])
                                      .snapshots()
                                      .map((snapshot) => snapshot.docs.length),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    }
                                    if (snapshot.hasError) {
                                      return const Text('Error');
                                    }
                                    final count = snapshot.data ?? 0;
                                    return Text(
                                      "CAR: $count/$carSlot",
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    );
                                  },
                                ),
                              if (isExpired)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize:
                                          const Size(double.infinity, 50),
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SubscriptionPackage(
                                            parkingId: docId,
                                            name: locationName,
                                            price: price,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Renew",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  void toggleStatusp(String parkingId, String currentStatus) async {
    String newStatus = currentStatus == "Online" ? "Offline" : "Online";

    await FirebaseFirestore.instance
        .collection('parking') // updated to 'parking'
        .doc(parkingId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        title: Text('ownermain'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            nameProfile(),
            const SizedBox(height: 14),
            buttonthree(context),
            const SizedBox(height: 14),
            Text(
              'ownermain'.tr(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            parkLocation(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).cardColor,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
            ),
            builder: (BuildContext context) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                height: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.map),
                      title: Text('addparking'.tr()),
                      onTap: () {
                        Navigator.pop(context); // Close the bottom sheet
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (c) => MapApi()));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.emoji_people),
                      title: Text('addemp'.tr()),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => emp_register()),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(
          Icons.add,
          size: 35,
          color: Colors.blue,
        ),
      ),
    );
  }
}
