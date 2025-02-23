import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class emp_main extends StatefulWidget {
  final String empId;
  const emp_main({super.key, required this.empId});

  @override
  State<emp_main> createState() => _emp_mainState();
}

class _emp_mainState extends State<emp_main> {
  final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  late String emp_id;

  @override
  void initState() {
    super.initState();
    emp_id = widget.empId;
    print('Logged-in emp_id: $emp_id');
  }

  Stream<DocumentSnapshot> getEmployeeData() {
    return FirebaseFirestore.instance
        .collection('employees')
        .doc(emp_id)
        .snapshots();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        if (kIsWeb) {
          _imageBytes = await pickedFile.readAsBytes();
        } else {
          _selectedImage = File(pickedFile.path);
        }
        await _uploadImageToCloudinary();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No image selected')));
      }
    } catch (e) {
      print("Error selecting image: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error selecting image')));
    }
  }

  Future<void> _uploadImageToCloudinary() async {
    try {
      if (_selectedImage == null && _imageBytes == null) return;

      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset;

      if (_imageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', _imageBytes!, filename: 'profile_image.jpg'));
      } else if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath('file', _selectedImage!.path));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final data = jsonDecode(responseData.body);
        final imageUrl = data['secure_url'];

        await FirebaseFirestore.instance.collection('employees').doc(emp_id).update({'profileImage': imageUrl});

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile image updated successfully!')));
      } else {
        print("Upload failed with status: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image.')));
      }
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error uploading image.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Profile"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: getEmployeeData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No employee data found."));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final empId = userData['emp_id'] ?? 'N/A';
          final firstName = userData['firstname'] ?? 'N/A';
          final lastName = userData['lastname'] ?? 'N/A';
          final age = userData['age']?.toString() ?? 'N/A';
          final dateOfBirth = userData['date_of_birth'] ?? 'N/A';
          final profileImage = userData['profileImage'] ?? 'N/A';

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(profileImage),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "$firstName $lastName",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text("Change Profile Picture"),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.badge),
                              title: const Text("Employee ID"),
                              subtitle: Text(empId),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.person),
                              title: const Text("Name"),
                              subtitle: Text("$firstName $lastName"),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.cake),
                              title: const Text("Age"),
                              subtitle: Text(age),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: const Text("Date of Birth"),
                              subtitle: Text(dateOfBirth),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
