import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:parking1/cash/receip.dart';
import 'package:parking1/homepage.dart';

class Vechicle extends StatefulWidget {

  @override
  State<Vechicle> createState() => _VechicleState();
}

class _VechicleState extends State<Vechicle> {
  File? _selectedImage;
  Uint8List? _imageBytes; // For web image bytes
  final ImagePicker _picker = ImagePicker();

  final TextEditingController brandNameController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController placeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";

  // Pick Image Function
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        if (kIsWeb) {
          final Uint8List bytes = await pickedFile.readAsBytes();
          setState(() {
            _imageBytes = bytes;
            _selectedImage = null; // Ensure mobile File is null
          });
        } else {
          setState(() {
            _selectedImage = File(pickedFile.path);
            _imageBytes = null; // Ensure web bytes are null
          });
        }
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

  // Upload Image to Cloudinary and Return URL
  Future<String?> _uploadImageToCloudinary() async {
    try {
      if (_selectedImage == null && _imageBytes == null) {
        return null;
      }

      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset;

      if (_imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', _imageBytes!),
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
        return data['secure_url']; // Return Cloudinary Image URL
      } else {
        print("Cloudinary Upload Failed: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      return null;
    }
  }
Future<void> _savePaymentData() async {
  if (_selectedImage == null && _imageBytes == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please upload an image before proceeding.")),
    );
    return;
  }

  String? imageUrl = await _uploadImageToCloudinary();
  if (imageUrl == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Image upload failed.")),
    );
    return;
  }

  // Simulate a timeout (e.g., 3 seconds delay)
  await Future.delayed(const Duration(seconds: 3));

  // ✅ Generate custom document ID (e.g., vehicle1234)
  String documentId = "vehicle${DateTime.now().millisecondsSinceEpoch}";

  // Save payment data with custom document ID
  FirebaseFirestore.instance.collection('vehicles').doc(documentId).set({
    "brandName": brandNameController.text,
    "color": colorController.text,
    "place": placeController.text,
    "imageUrl": imageUrl,
    "timestamp": FieldValue.serverTimestamp(),
  }).then((_) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data saved successfully!")),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => Homepage(), // Pass document ID
      ),
    );
  }).catchError((error) {
    print("Error saving data: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saving data failed. Try again.")),
    );
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Vehicle Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: brandNameController,
              decoration: InputDecoration(
                labelText: "Brand Name",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: colorController,
              decoration: InputDecoration(
                labelText: "Color",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: placeController,
              decoration: InputDecoration(
                labelText: "licence_Place",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Owner's Name",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Upload Picture",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child:
                                Image.memory(_imageBytes!, fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Text("Tap to upload",
                                style: TextStyle(color: Colors.grey)),
                          ),
              ),
            ),
            const SizedBox(height: 40),

            Center(
              child: ElevatedButton(
                onPressed: _savePaymentData,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  "Save Vehicle Info",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
