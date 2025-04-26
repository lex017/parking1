import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parking1/chose/ownerMain.dart';

class BtnaddParking extends StatefulWidget {
  final String address;
  final double latitude;
  final double longitude;

  const BtnaddParking({
    Key? key,
    required this.address,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<BtnaddParking> createState() => _BtnaddParkingState();
}

class _BtnaddParkingState extends State<BtnaddParking> {
  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";
  File? _selectedImage;
  File? _parkingImage;
  Uint8List? _parkingImageBytes;

  File? _qrImage;
  Uint8List? _qrImageBytes;

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _selectedEVOption;
  final List<String> _evOptions = ["EV", "None"];

  // Move form key and controllers to class-level
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _carSlotController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.address;
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _carSlotController.dispose();
    super.dispose();
  }

  // Function to upload image to Cloudinary
 Future<String?> _uploadImageToCloudinary({File? imageFile, Uint8List? imageBytes}) async {
  try {
    var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
      ..fields['upload_preset'] = uploadPreset;

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: 'image.jpg'),
      );
    } else if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
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

  // Function to add parking location with image and other details
  Future<void> _addLocationWithImage(
  String name,
  String address,
  String description,
  int price,
  int carSlot,
  String evSupport,
) async {
  try {
    final String? imageUrl = await _uploadImageToCloudinary(
      imageFile: _parkingImage,
      imageBytes: _parkingImageBytes,
    );

    final String? qrImage = await _uploadImageToCloudinary(
      imageFile: _qrImage,
      imageBytes: _qrImageBytes,
    );

    if (imageUrl != null && qrImage != null) {
      User? currentUser = FirebaseAuth.instance.currentUser;
      String ownerId = currentUser?.uid ?? 'unknown_owner';

      final collection = FirebaseFirestore.instance.collection('parking');
      final snapshot = await collection.get();
      final newId = "location${snapshot.docs.length + 1}";

      await collection.doc(newId).set({
        'nameparking': name,
        'address': address,
        'description': description,
        'price': price,
        'status': 'N/A',
        'car_slot': carSlot,
        'imageUrl': imageUrl,
        'qrImage': qrImage,
        'location': GeoPoint(widget.latitude, widget.longitude),
        'ownerId': ownerId,
        'evSupport': evSupport,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location added successfully with ID: $newId')),
      );

      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(builder: (c) => ownerMain()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image upload failed')),
      );
    }
  } catch (e) {
    print("Error adding location: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to add location: $e')),
    );
  }
}


  Widget _addLocationForm() {
    return SingleChildScrollView(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Detail parking",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Location Name",
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter the location name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: "Address",
                    prefixIcon: Icon(Icons.map),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter the address";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter the description";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Price",
                    prefixIcon: Icon(Icons.price_change),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter the price";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
               
                DropdownButtonFormField<String>(
                  value: _selectedEVOption,
                  decoration: const InputDecoration(
                    labelText: "EV Charging Support",
                    prefixIcon: Icon(Icons.electric_car),
                  ),
                  items: _evOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedEVOption = newValue;
                    });
                  },
                  validator: (value) =>
                      value == null ? "Please select an option" : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickParkingImage,
                  icon: const Icon(Icons.image, color: Colors.blue),
                  label: const Text("Pick Parking Image",
                      style: TextStyle(color: Colors.blue)),
                ),
                if (_parkingImage != null || _parkingImageBytes != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _parkingImage != null
                        ? Image.file(_parkingImage!, height: 150)
                        : Image.memory(_parkingImageBytes!, height: 150),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickQRImage,
                  icon: const Icon(Icons.qr_code, color: Colors.blue),
                  label: const Text("Pick QR Image",
                      style: TextStyle(color: Colors.blue)),
                ),
                if (_qrImage != null || _qrImageBytes != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _qrImage != null
                        ? Image.file(_qrImage!, height: 150)
                        : Image.memory(_qrImageBytes!, height: 150),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null // Disable button while loading
                        : () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              setState(() {
                                _isLoading = true; // Show loading indicator
                              });

                              try {
                                final name = _nameController.text.trim();
                                final address = _addressController.text.trim();
                                final description =
                                    _descriptionController.text.trim();
                                final price =
                                    int.parse(_priceController.text.trim());
                                final carSlot =
                                    int.parse(_carSlotController.text.trim());
                                final evSupport = _selectedEVOption ?? "None";

                                await _addLocationWithImage(name, address,
                                    description, price, carSlot, evSupport);
                              } catch (e) {
                                print("Error: $e");
                              } finally {
                                setState(() {
                                  _isLoading = false; // Hide loading indicator
                                });
                              }
                            }
                          },
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Next",
                            style: TextStyle(color: Colors.blue),
                          ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Image picking function
  Future<void> _pickParkingImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _parkingImage = File(pickedFile.path);
        _parkingImageBytes = File(pickedFile.path).readAsBytesSync();
      });
    }
  }

  Future<void> _pickQRImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _qrImage = File(pickedFile.path);
        _qrImageBytes = File(pickedFile.path).readAsBytesSync();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Parking Location")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _addLocationForm(),
      ),
    );
  }
}
