import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parking1/chose/mapapi.dart';
import 'package:parking1/data_save/btnadd_parking.dart';
import 'package:parking1/map_api/map_api.dart';
import 'package:parking1/menu/emp_register.dart';

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

  void toggleStatus(String currentStatus) async {
    String newStatus = currentStatus == "Online" ? "Offline" : "Online";

    await FirebaseFirestore.instance
        .collection('users')
        .doc(auth.currentUser?.uid)
        .update({'status': newStatus});
  }

  Widget ticketWidget({
    required String title,
    required String date,
    required String status,
    required VoidCallback onToggle,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Date: $date",
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  "Status: $status",
                  style: TextStyle(
                    fontSize: 14,
                    color: status.toLowerCase() == 'online'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: onToggle,
                  icon: const Icon(Icons.power_settings_new),
                  label: Text(status == "Online" ? "Go Offline" : "Go Online"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        status == "Online" ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget nameProfile() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return const Center(
            child: Text(
              'Error loading profile',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
          );
        } else {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final username = userData['username'] ?? 'Guest';
          final status = userData['status'] ?? 'Offline';

          return StreamBuilder<String>(
            stream: _realTimeDateStream,
            builder: (context, dateSnapshot) {
              final realTimeDate = dateSnapshot.data ?? "Loading...";
              return ticketWidget(
                title: username,
                date: realTimeDate,
                status: status,
                onToggle: () => toggleStatus(status),
              );
            },
          );
        }
      },
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
      await FirebaseFirestore.instance.collection('Locations').add({
        'nameLocation': name,
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

  Widget parkLocation() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Locations').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text(
              'Error loading locations',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
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
              final locationName =
                  locationData['nameLocation'] ?? 'Unknown Location';
              final addressName = locationData['address'] ?? 'Unknown Address';
              final description =
                  locationData['description'] ?? 'No Description Available';
              final price = locationData['price'] ?? 'Unknown';
              final carSlot = locationData['car_slot'] ?? 'Unknown';
              final imageUrl = locationData['imageUrl'] ?? '';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Parking Location ${index + 1}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (imageUrl.isNotEmpty)
                        Image.network(
                          imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text("Failed to load image"),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        "Location: $locationName",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Address: $addressName",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Car Slots: 0/$carSlot",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Price: $price",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.map),
                        label: const Text("Open in Maps"),
                        onPressed: () {
                          Navigator.of(context).pop();
                          MaterialPageRoute route =
                              MaterialPageRoute(builder: (c) => map_api());
                          Navigator.of(context).push(route);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  void _showAddLocationDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _addressController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _priceController = TextEditingController();
    final _carSlotController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Row(
            children: const [
              Icon(Icons.add_location_alt, color: Colors.blue, size: 30),
              SizedBox(width: 8),
              Text(
                "Add New Location",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Location Name",
                      prefixIcon:
                          const Icon(Icons.location_on, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
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
                    decoration: InputDecoration(
                      labelText: "Address",
                      prefixIcon:
                          const Icon(Icons.location_on, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
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
                    decoration: InputDecoration(
                      labelText: "Description",
                      prefixIcon:
                          const Icon(Icons.description, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
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
                    decoration: InputDecoration(
                      labelText: "Price",
                      prefixIcon: const Icon(Icons.link, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter price";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _carSlotController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Car Slots (min 3)",
                      prefixIcon:
                          const Icon(Icons.directions_car, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    validator: (value) {
                      final carSlot = int.tryParse(value ?? '') ?? 0;
                      if (carSlot < 3) {
                        return "Car slots must be at least 3";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Pick Image"),
                  ),
                  if (_selectedImage != null || _imageBytes != null)
                    Column(
                      children: [
                        if (_selectedImage != null)
                          Image.file(
                            _selectedImage!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        else if (_imageBytes != null)
                          Image.memory(
                            _imageBytes!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        const SizedBox(height: 10),
                        const Text(
                          "Image picked and ready to upload.",
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  final name = _nameController.text.trim();
                  final address = _addressController.text.trim();
                  final description = _descriptionController.text.trim();
                  final price = int.parse(_priceController.text.trim());
                  final carSlot = int.parse(_carSlotController.text.trim());
                  await _addLocationWithCustomId(
                      name, address, description, price, carSlot);
                  Navigator.pop(context);
                }
              },
              child: const Text(
                "Add",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addLocationWithCustomId(String name, String address,
      String description, int price, int carSlot) async {
    final collection = FirebaseFirestore.instance.collection('Locations');
    final snapshot = await collection.get();
    final newId = "location${snapshot.docs.length + 1}";

    final imageUrl = await _uploadImageToCloudinary();

    if (imageUrl != null) {
      await collection.doc(newId).set({
        'nameLocation': name,
        'address': address,
        'description': description,
        'price': price,
        'car_slot': carSlot,
        'imageUrl': imageUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location added successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image upload failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Owner Main"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            nameProfile(),
            const SizedBox(height: 16),
            parkLocation(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
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
                      title: const Text('Add Marker'),
                      onTap: () {
                        Navigator.pop(context); // Close the bottom sheet
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (c) => MapApi()));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Add Employee'),
                      onTap: () {
                        Navigator.pop(context); // Close the bottom sheet
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (c) => emp_register()));
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
          color: Colors.black,
        ),
      ),
    );
  }
}
