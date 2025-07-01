import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class EditEmployeeForm extends StatefulWidget {
  final Map<String, dynamic> employee;

  const EditEmployeeForm({super.key, required this.employee});

  @override
  State<EditEmployeeForm> createState() => _EditEmployeeFormState();
}

class _EditEmployeeFormState extends State<EditEmployeeForm> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _ageController;
  late TextEditingController _genderController;
  late TextEditingController _empIdController;
  late TextEditingController _passwordController;

  File? _selectedImage;
  Uint8List? _imageBytes;
  String? _imageUrl;

  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";

  @override
  void initState() {
    super.initState();
    _firstnameController =
        TextEditingController(text: widget.employee['firstname']);
    _lastnameController =
        TextEditingController(text: widget.employee['lastname']);
    _ageController = TextEditingController(text: widget.employee['age']);
    _genderController = TextEditingController(text: widget.employee['gender']);
    _empIdController = TextEditingController(text: widget.employee['emp_id']);
    _passwordController =
        TextEditingController(text: widget.employee['password'] ?? '');
    _imageUrl = widget.employee['profileImage'];
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImageToCloudinary() async {
    try {
      if (_selectedImage == null && _imageBytes == null) return null;

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

  void showConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Confirm Save"),
          content: const Text("Are you sure you want to save the changes?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                saveChanges(); // Save changes
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text("Yes, Save",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void saveChanges() async {
    if (_formKey.currentState!.validate()) {
      String? imageUrl = _imageUrl;

      if (_selectedImage != null) {
        imageUrl = await _uploadImageToCloudinary();
      }

      await _firestore
          .collection('employees')
          .doc(widget.employee['id'])
          .update({
        'firstname': _firstnameController.text,
        'lastname': _lastnameController.text,
        'age': _ageController.text,
        'gender': _genderController.text,
        'emp_id': _empIdController.text,
        'password': _passwordController.text,
        'profileImage': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Employee updated successfully!')),
      );

      Navigator.pop(context);
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Employee'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Employee Information',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_imageUrl != null
                                      ? NetworkImage(_imageUrl!)
                                      : const AssetImage('assets/avatar.png'))
                                  as ImageProvider,
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          icon: const Icon(Icons.image, color: Colors.white),
                          label: const Text(
                            "Change Image",
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: _pickImage,
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Colors.blueAccent, // background color here
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                      controller: _firstnameController, label: 'First Name'),
                  buildTextField(
                      controller: _lastnameController, label: 'Last Name'),
                  buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      keyboardType: TextInputType.number),
                  buildTextField(
                      controller: _genderController, label: 'Gender'),
                  buildTextField(
                      controller: _empIdController, label: 'Employee ID'),
                  buildTextField(
                      controller: _passwordController, label: 'Password'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.save,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () => showConfirmDialog(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
