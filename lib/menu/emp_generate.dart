import 'dart:typed_data';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:parking1/menu/real_ticket.dart';
import 'dart:convert';

class EmpGenerate extends StatefulWidget {
  final String empId; // Employee ID
  final String locationId; // Location ID

  const EmpGenerate({
    super.key,
    required this.empId,
    required this.locationId,
  });

  @override
  State<EmpGenerate> createState() => _EmpGenerateState();
}

class _EmpGenerateState extends State<EmpGenerate> {
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _selectedProvince;
  String? _selectedPlateType;
  // Employee and Location IDs passed via the constructor
  late String empId = widget.empId;
  late String locationId = widget.locationId;

  final TextEditingController nameplateController = TextEditingController();
  final TextEditingController plateController = TextEditingController();

  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";

  final List<String> _provinces = [
    "ແຂວງຄໍາມ່ວນ",
    "ແຂວງຈໍາປາສັກ",
    "ແຂວງຊຽງຂວາງ",
    "ແຂວງໄຊຍະບູລີ",
    "ແຂວງໄຊສົມບູນ",
    "ແຂວງເຊກອງ",
    "ແຂວງບໍລິຄໍາໄຊ",
    "ແຂວງບໍ່ແກ້ວ",
    "ແຂວງຜົ້ງສາລີ",
    "ແຂວງວຽງຈັນ",
    "ແຂວງສາລະວັນ",
    "ແຂວງສະຫວັນນະເຂດ",
    "ແຂວງຫຼວງນ້ຳທາ",
    "ແຂວງຫຼວງພະບາງ",
    "ແຂວງຫົວພັນ",
    "ແຂວງອັດຕະປື",
    "ແຂວງອຸດົມໄຊ",
    "ນະຄອນຫຼວງວຽງຈັນ",
  ];

  final Map<String, Map<String, Color>> _plateColors = {
    "ລັດບໍລິຫານ": {"background": Colors.blue, "text": Colors.white},
    "ເອກະຊົນລາວ": {"background": Colors.yellow, "text": Colors.black},
    "ບໍລິສັດ/ທຸລະກິດ 100%": {"background": Colors.white, "text": Colors.black},
    "ບໍລິສັດ/ທຸລະກິດ 1%": {"background": Colors.white, "text": Colors.blue},
    "ເອກະຊົນຕ່າງດ້າວ": {"background": Colors.yellow, "text": Colors.lightBlue},
    "ອົງການຈັດຕັ້ງສາກົນ(ນຳໃຊ້ສ່ວນຕົວ)": {
      "background": Colors.white,
      "text": Colors.lightBlue
    },
  };
  Future<String?> _uploadImageToCloudinary() async {
    try {
      if (_selectedImage == null && _imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select an image')));
        return null;
      }
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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')));
        return null;
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error uploading image')));
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Select Image Source"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: const Text("Take Photo"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: const Text("Choose from Gallery"),
              ),
            ],
          );
        },
      );

      if (source != null) {
        final XFile? pickedFile = await _picker.pickImage(source: source);
        if (pickedFile != null) {
          if (kIsWeb) {
            final Uint8List bytes = await pickedFile.readAsBytes();
            setState(() {
              _imageBytes = bytes;
              _selectedImage = null;
            });
          } else {
            setState(() {
              _selectedImage = File(pickedFile.path);
              _imageBytes = null;
            });
          }
        }
      }
    } catch (e) {
      print("Error selecting image: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error selecting image')));
    }
  }

  Future<void> _saveTicketToFirebase() async {
    if (_selectedProvince == null ||
        _selectedPlateType == null ||
        nameplateController.text.isEmpty ||
        plateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Image upload is optional now
    String? imageUrl;
    if (_selectedImage != null || _imageBytes != null) {
      imageUrl = await _uploadImageToCloudinary();
      if (imageUrl == null) {
        setState(() {
          _isLoading = false;
        });
        return; // Exit if image upload failed
      }
    }

    // Custom ticket ID generation
    String ticketId = "ticket${DateTime.now().millisecondsSinceEpoch}";

    Map<String, dynamic> ticketData = {
      "province": _selectedProvince,
      "plateType": _selectedPlateType,
      "namePlate": nameplateController.text,
      "plate": plateController.text,
      "empId": empId, // Add empId here
      "locationId": locationId, // Add locationId here
      "imageUrl": imageUrl ?? "", // Handle optional image
      "Status": "check-in",
      "timestamp": FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection("ticketreal")
          .doc(ticketId) // Use the custom ticket ID
          .set(ticketData);

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => RealTicket(ticketData: ticketData)),
        );
      }
    } catch (e) {
      print("Error saving ticket: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate ticket')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Ticket'),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Generate Ticket",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: _selectedProvince,
              items: _provinces.map((String province) {
                return DropdownMenuItem<String>(
                    value: province, child: Text(province));
              }).toList(),
              onChanged: (value) => setState(() => _selectedProvince = value),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              hint: const Text("Select Province"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPlateType,
              items: _plateColors.keys.map((String color) {
                return DropdownMenuItem<String>(
                    value: color, child: Text(color));
              }).toList(),
              onChanged: (value) => setState(() => _selectedPlateType = value),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.car_repair),
              ),
              hint: const Text("Select Plate Type"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameplateController,
              decoration: InputDecoration(
                labelText: "NamePlate",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
             const SizedBox(height: 20),
            TextField(
              controller: plateController,
              keyboardType: TextInputType.number, // Set keyboard type to number
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly, // Allow only digits
              ],
              decoration: InputDecoration(
                labelText: "Plate",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Upload Picture",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                        : const Center(
                            child: Text("Tap to upload",
                                style: TextStyle(color: Colors.grey))),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTicketToFirebase,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _isLoading
                      ? Colors.grey
                      : Colors.blueAccent, // Button color
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16), // Increased padding for a larger button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // More rounded
                  ),
                  elevation: _isLoading ? 0 : 5, // Add shadow when not loading
                  minimumSize:
                      const Size(200, 60), // Set a minimum size for the button
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white), // Spinner color
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Generate",
                        style: TextStyle(
                          fontSize:
                              20, // Increased font size for better visibility
                          fontWeight: FontWeight.bold, // Bold text
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
