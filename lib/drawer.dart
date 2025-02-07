import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parking1/chose/Owner.dart';
import 'package:parking1/chose/mapapi.dart';
import 'package:parking1/constant/CloudinaryUploader.dart';
import 'package:parking1/homepage.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:parking1/loginandregis/loginPage.dart';
import 'package:parking1/map_api/LocationPage.dart';
import 'package:parking1/map_api/map_api.dart';
import 'package:parking1/menu/Help.dart';
import 'package:parking1/menu/Wallet.dart';
import 'package:parking1/menu/employeescan.dart';
import 'package:parking1/menu/history.dart';
import 'package:shared_preferences/shared_preferences.dart';

class drawer_menu extends StatefulWidget {
  const drawer_menu({super.key});

  @override
  State<drawer_menu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<drawer_menu> {
  final auth = FirebaseAuth.instance;
  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
    await prefs.remove('rememberMe');

    // Sign out from FirebaseAuth
    await FirebaseAuth.instance.signOut();

    setState(() {
      // Optional: Update state if necessary
    });

    // Navigate to the login page
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const loginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(),
            accountName: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(auth.currentUser
                      ?.uid) // Get the user's document based on their UID
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!.exists) {
                  return const Text(
                    'No Name Found',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                return Text(
                  data['username'] ?? 'No Name Found',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            accountEmail: Text(
              auth.currentUser?.email ?? '', // Display the current user's email
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            currentAccountPicture: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 45,
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
                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          !snapshot.data!.exists) {
                        return Image.asset(
                          'images/profile-user.png',
                          fit: BoxFit.cover,
                          width: 90,
                          height: 90,
                        );
                      }

                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final profileImage =
                          data['profileImage'] ?? 'images/profile-user.png';

                      return Image.network(
                        profileImage,
                        fit: BoxFit.cover,
                        width: 90,
                        height: 90,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                          'images/profile-user.png',
                          fit: BoxFit.cover,
                          width: 90,
                          height: 90,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: ListTile(
              title: Text(
                'Home',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                MaterialPageRoute route =
                    MaterialPageRoute(builder: (c) => Homepage());
                Navigator.of(context).push(route);
              },
            ),
          ),
          TextButton(
            onPressed: () {},
            child: ListTile(
              title: Text(
                'Location',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                MaterialPageRoute route =
                    MaterialPageRoute(builder: (c) => LocationPage());
                Navigator.of(context).push(route);
              },
            ),
          ),
          TextButton(
            onPressed: () {},
            child: ListTile(
              title: Text(
                'History',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                MaterialPageRoute route =
                    MaterialPageRoute(builder: (c) => history());
                Navigator.of(context).push(route);
              },
            ),
          ),
          TextButton(
            onPressed: () {},
            child: ListTile(
              title: Text(
                'My Ticket',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          TextButton(
            onPressed: () {},
            child: ListTile(
              title: Text(
                'Wallet',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                MaterialPageRoute route =
                    MaterialPageRoute(builder: (c) => Wallet());
                Navigator.of(context).push(route);
              },
            ),
          ),
          TextButton(
            onPressed: () {},
            child: ListTile(
              title: Text(
                'EmployeeScan',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                MaterialPageRoute route =
                    MaterialPageRoute(builder: (c) => EmployeeScan());
                Navigator.of(context).push(route);
              },
            ),
          ),
          TextButton(
            onPressed: () {},
            child: ListTile(
              title: Text(
                'Setting',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          TextButton(
            onPressed: () {},
            child: ListTile(
              title: Text(
                'Owner',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                MaterialPageRoute route =
                    MaterialPageRoute(builder: (c) => Owner());
                Navigator.of(context).push(route);
              },
            ),
          ),
          TextButton(
            onPressed: () {},
            child: ListTile(
              title: Text(
                'Help',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                MaterialPageRoute route =
                    MaterialPageRoute(builder: (c) => Help());
                Navigator.of(context).push(route);
              },
            ),
          ),
          TextButton(
            onPressed: () {},
            child: ListTile(
              title: Text(
                'upload',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                MaterialPageRoute route =
                    MaterialPageRoute(builder: (c) => CloudinaryUploader());
                Navigator.of(context).push(route);
              },
            ),
          ),
          TextButton(
            onPressed: () {},
            child: ListTile(
              title: Text(
                'GPS',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                MaterialPageRoute route =
                    MaterialPageRoute(builder: (c) => map_api());
                Navigator.of(context).push(route);
              },
            ),
          ),
          TextButton(
            onPressed: () {},
            child: ListTile(
              title: Text(
                'GPS_maker',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                MaterialPageRoute route =
                    MaterialPageRoute(builder: (c) => MapApi());
                Navigator.of(context).push(route);
              },
            ),
          ),
          TextButton(
            onPressed: () async {
              await logout();
            },
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.black),
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
