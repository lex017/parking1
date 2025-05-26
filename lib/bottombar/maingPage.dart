import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:parking1/bottombar/vechicle.dart';
import 'package:parking1/chose/Owner.dart';

import 'package:parking1/map_api/map_api.dart';
import 'package:parking1/menu/Help.dart';

import 'package:parking1/menu/employee_login.dart';
import 'package:parking1/menu/history.dart';

class mainPage extends StatefulWidget {
  const mainPage({super.key});

  @override
  State<mainPage> createState() => _MainPageState();
}

class _MainPageState extends State<mainPage> {
  final auth = FirebaseAuth.instance;
  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  final String cloudinaryApiUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/resources/image";

  List<String> adImages = [
    'https://res.cloudinary.com/doiq3nkso/image/upload/v1736348080/sivz7kpn9yhcajh6r0mb.jpg',
    'https://res.cloudinary.com/doiq3nkso/image/upload/v1736348049/ojs7n8aufknyoerqfxex.jpg',
    'https://res.cloudinary.com/doiq3nkso/image/upload/v1736348850/jwufyzc7imcwz3ylpi5d.png'
  ];

  @override
  void initState() {
    super.initState();
    fetchAdImages();
  }

  /// Fetch ad images from Cloudinary
  Future<void> fetchAdImages() async {
    try {
      // Replace with your Cloudinary API Key and Secret.
      const cloudinaryApiKey = "432378133179461";
      const cloudinaryApiSecret = "J7PLX9YnL1aT64A02nS1LcSSv00";
      const folder = "public_upload"; // Replace with your Cloudinary folder.

      final authHeader = "Basic " +
          base64Encode(utf8.encode("$cloudinaryApiKey:$cloudinaryApiSecret"));

      final response = await http.get(
        Uri.parse('$cloudinaryApiUrl?prefix=$folder'),
        headers: {"Authorization": authHeader},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List resources = data['resources'] ?? [];
        final List<String> fetchedUrls =
            resources.map((item) => item['secure_url'] as String).toList();

        setState(() {
          adImages = fetchedUrls;
        });
      } else {
        print("Failed to fetch images: ${response.body}");
      }
    } catch (e) {
      print("Error fetching images: $e");
    }
  }

  // Function to fetch the username from Firestore for the current user
  Future<String> getUserName() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.currentUser?.uid)
          .get();

      if (userDoc.exists) {
        return userDoc['username'] ?? 'Unknown'; // Return username or 'Unknown'
      }
      return 'Unknown'; // Return 'Unknown' if the document doesn't exist
    } catch (e) {
      print("Error fetching username: $e");
      return 'Unknown'; // Return 'Unknown' in case of error
    }
  }

  Widget adSlider() {
    if (adImages.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: adImages.length,
        itemBuilder: (context, index) {
          return adCard(
            imageUrl: adImages[index],
          );
        },
      ),
    );
  }

  Widget adCard({
    required String imageUrl,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      // elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            'assets/images/profile-user.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget dashboardSection(BuildContext context) {
    // Accept BuildContext
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          dashboardButton(
            iconPath: 'assets/images/location-pin.png',
            label: 'Find parking',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => map_api(documentId: 'documentId')),
              );
            },
          ),
          dashboardButton(
            iconPath: 'assets/images/history.png',
            label: 'History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => history()),
              );
            },
          ),
          dashboardButton(
            iconPath: 'assets/images/hatchback.png',
            label: 'Vehicle',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => Vechicle()),
              );
            },
          ),
          dashboardButton(
            iconPath: 'assets/images/help.png',
            label: 'Help',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => Help()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget dashboardButton({
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
              color: const Color.fromARGB(255, 227, 227, 227),
              width: 2.0,
            ),
          ),
          margin: EdgeInsets.zero,
          child: Container(
            width: 120,
            height: 140,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  iconPath,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          });
        } else {
          setState(() {
            _selectedImage = File(pickedFile.path);
          });
        }

        // Upload image to Cloudinary after selection
        await _uploadImageToCloudinary();
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

  Future<void> _uploadImageToCloudinary() async {
    try {
      if (_selectedImage == null && _imageBytes == null) {
        return;
      }

      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset;

      if (_imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', _imageBytes!,
              filename: 'profile_image.jpg'),
        );
      } else if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', _selectedImage!.path),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final data = jsonDecode(responseData.body);
        final imageUrl = data['secure_url'];

        // Update Firestore with the new image URL
        await FirebaseFirestore.instance
            .collection('users')
            .doc(auth.currentUser?.uid)
            .update({'profileImage': imageUrl});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully!')),
        );
      } else {
        print("Upload failed with status: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
  preferredSize: const Size.fromHeight(100), // ปรับขนาด AppBar
  child: SafeArea(
    top: true, // ป้องกันไม่ให้ AppBar ชิดขอบจอ
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0), // ปรับระยะห่าง
      child: AppBar(
        toolbarHeight: 90.0, // ปรับความสูงของ AppBar
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        // elevation: 4, // เพิ่มเงาให้ AppBar
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // ทำให้มุม AppBar โค้งมน
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PopupMenuButton<String>(
                icon: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        print("Image tapped!");
                      },
                      child: Image.asset(
                        'assets/images/reference.png',
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ປ່ຽນ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
                onSelected: (String result) {
                  if (result == 'owner') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => Owner()),
                    );
                  } else if (result == 'employee') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => emp_login()),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'owner',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.manage_accounts, color: Colors.grey),
                        SizedBox(width: 10),
                        Text('Owner'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'employee',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.emoji_people, color: Colors.grey),
                        SizedBox(width: 10),
                        Text('Employee'),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    FutureBuilder<String>(
                      future: getUserName(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        if (snapshot.hasError) {
                          return Text(
                            'Error loading username',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          );
                        }

                        final username = snapshot.data ?? 'No Name Found';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Status: user',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              username,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 28,
                        child: ClipOval(
                          child: FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(auth.currentUser?.uid)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }
                              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                                return Image.asset(
                                  'images/profile-user.png',
                                  fit: BoxFit.cover,
                                  width: 60,
                                  height: 60,
                                );
                              }

                              final data = snapshot.data!.data() as Map<String, dynamic>;
                              final profileImage = data['profileImage'] ?? 'images/profile-user.png';

                              return Image.network(
                                profileImage,
                                fit: BoxFit.cover,
                                width: 60,
                                height: 60,
                                errorBuilder: (context, error, stackTrace) => Image.asset(
                                  'images/profile-user.png',
                                  fit: BoxFit.cover,
                                  width: 60,
                                  height: 60,
                                ),
                              );
                            },
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
    ),
  ),
),

      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Background color based on theme
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            adSlider(), // Assuming this widget is created somewhere else
            const SizedBox(height: 24),
            const Text(
              'Features',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            dashboardSection(
                context), // Assuming this widget is created somewhere else
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: mainPage(),
  ));
}
