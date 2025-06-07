import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class EditProfilePage extends StatefulWidget {
  final File? currentImage;

  const EditProfilePage({Key? key, this.currentImage}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";

  TextEditingController _phoneController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  String? _profileImage;
  String? _selectedGender = 'Male';
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.currentImage;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _usernameController.text = data['username'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _selectedGender = data['gender'] ?? 'Male';
          _profileImage = data['profileImage'];
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      await _uploadImageToCloudinary();
    }
  }

  Future<void> _uploadImageToCloudinary() async {
    try {
      if (_selectedImage == null) return;
      setState(() => _isLoading = true);

      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset;

      request.files.add(await http.MultipartFile.fromPath('file', _selectedImage!.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final data = jsonDecode(responseData.body);
        final imageUrl = data['secure_url'];

        // Update Firestore with the new profile image URL
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .update({'profileImage': imageUrl});

        setState(() {
          _profileImage = imageUrl;
        });

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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    try {
      setState(() => _isLoading = true);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .update({
        'username': _usernameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneController.text,
        'gender': _selectedGender,
        'profileImage': _profileImage,
      });

      _fetchUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB2FEFA), Color(0xFF0ED2F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Card(
                elevation: 10,
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : _profileImage != null
                                      ? NetworkImage(_profileImage!) as ImageProvider
                                      : const AssetImage('images/profile-user.png'),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person),
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email),
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.phone),
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        items: _genders
                            .map((gender) => DropdownMenuItem<String>(
                                  value: gender,
                                  child: Text(gender),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.wc),
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _updateProfile,
                          icon: const Icon(Icons.save),
                          label: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Save Changes",style: TextStyle(color: Colors.white),),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}