import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:parking1/cash/receip.dart';

class PayPage extends StatefulWidget {
  final int packageHours;

  const PayPage({super.key, required this.packageHours});

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  File? _selectedImage;
  Uint8List? _imageBytes; // For web image bytes
  final ImagePicker _picker = ImagePicker();

  final TextEditingController amountController = TextEditingController();
  final TextEditingController accountController = TextEditingController();
  final TextEditingController DateController = TextEditingController();
  final TextEditingController TimeController = TextEditingController();
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

  // Date Picker Function
  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      String formattedDate =
          "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      setState(() {
        DateController.text = formattedDate;
      });
    }
  }

  // Time Picker Function
  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      String formattedTime = pickedTime.format(context);
      setState(() {
        TimeController.text = formattedTime;
      });
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

  // Save Payment Data to Firestore
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

  // ✅ Generate custom document ID (e.g., payment1234)
  String documentId = "payment${DateTime.now().millisecondsSinceEpoch}";

  // Save payment data with custom document ID
  FirebaseFirestore.instance.collection('payments').doc(documentId).set({
    "amount": amountController.text,
    "Date": DateController.text,
    "Time": TimeController.text,
    "name": nameController.text,
    "imageBill": imageUrl,
    "status": "pending", // Initial status as pending
    "timestamp": FieldValue.serverTimestamp(),
  }).then((_) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment successful!")),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => BillPage(transactionId: documentId), // ✅ Pass document ID
      ),
    );
  }).catchError((error) {
    print("Error saving payment: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment failed. Try again.")),
    );
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Payment Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: "Amount",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // 📅 Date Picker Field
            TextFormField(
              controller: DateController,
              decoration: InputDecoration(
                labelText: "Select Date",
                hintText: "DD/MM/YY",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ),
              readOnly: true, // Prevent manual typing
            ),

            const SizedBox(height: 20),

            // ⏰ Time Picker Field
            TextFormField(
              controller: TimeController,
              decoration: InputDecoration(
                labelText: "Select Time",
                hintText: "HH:MM AM/PM",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: _pickTime,
                ),
              ),
              readOnly: true, // Prevent manual typing
            ),

            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Name",
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
                  backgroundColor: Colors.white,
                ),
                child: const Text(
                  "Pay Now",
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
