import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parking1/chose/detail_ownner.dart';
import 'package:parking1/chose/mapapi.dart';
import 'package:parking1/data_save/btnadd_parking.dart';
import 'package:parking1/detailownner/detail_money.dart';
import 'package:parking1/map_api/btnlocation.dart';
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

  void toggleStatus(String parkingId, String currentStatus) async {
    String newStatus = currentStatus == "Online" ? "Offline" : "Online";

    await FirebaseFirestore.instance
        .collection('parking') // Reference the "parking" collection
        .doc(parkingId) // Specify the document to update
        .update({'status': newStatus});
  }

  Widget ticketWidget({
    required String title,
    required String date,
    required String status,
    required String tel,
    required VoidCallback onToggle,
    required String profileImageUrl,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blueAccent,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(18.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile and Name
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(
                        profileImageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.person,
                              size: 30, color: Colors.grey);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),

              // Status Information
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Tel: 020 $tel",
                    style: TextStyle(
                      fontSize: 14,
                    ),
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
              const Divider(), // Line added above the switch

              // Switch, Status Toggle, and Date on the Right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Date: $date",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Row(
                    children: [
                      Text(status == "Online" ? "Go Offline" : "Go Online"),
                      const SizedBox(width: 8),
                      Switch(
                        value: status.toLowerCase() == 'online',
                        onChanged: (value) {
                          onToggle();
                        },
                        activeColor: Colors.green,
                        activeTrackColor: Colors.lightGreenAccent,
                        inactiveThumbColor: Colors.red,
                        inactiveTrackColor: Colors.redAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
          final tel = userData['phoneNumber'] ?? 'N/A';
          final profileImageUrl =
              userData['profileImage'] ?? ''; // Get profile image URL

          return StreamBuilder<String>(
            stream: _realTimeDateStream,
            builder: (context, dateSnapshot) {
              final realTimeDate = dateSnapshot.data ?? "Loading...";
              return ticketWidget(
                title: username,
                date: realTimeDate,
                status: status,
                tel: tel,
                onToggle: () => toggleStatus(auth.currentUser!.uid, status),
                profileImageUrl: profileImageUrl, // Pass the profile image URL
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
      await FirebaseFirestore.instance.collection('parking').add({
        'nameparking': name,
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

  Widget DashboardButton({
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
              color: Colors.blueAccent,
              width: 1.0,
            ),
          ),
          margin: EdgeInsets.zero,
          child: Container(
            width: 140,
            height: 140,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  iconPath,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 18),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buttonthree(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceEvenly, // จัดให้ปุ่มกระจายตัวเท่าๆ กัน
        children: [
          Expanded(
            child: DashboardButton(
              iconPath: 'assets/images/income.png',
              label: 'ລາຍຮັບ',
              onPressed: () {
                Navigator.of(context).pop();
                MaterialPageRoute route =
                    MaterialPageRoute(builder: (c) => DetailMoney());
                Navigator.of(context).push(route);
              },
            ),
          ),
          SizedBox(width: 15), // เพิ่มระยะห่าง
          Expanded(
            child: DashboardButton(
              iconPath: 'assets/images/ticket.png',
              label: 'ປະຫວັດ',
              onPressed: () {},
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: DashboardButton(
              iconPath: 'assets/images/question.png',
              label: 'ຊ່ວຍເຫຼືອ',
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget parkLocation() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String ownerId = currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('parking')
          .where('ownerId', isEqualTo: ownerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
              final docId = locations[index].id;
              final locationName =
                  locationData['nameparking'] ?? 'Unknown Location';
              final carSlot = locationData['car_slot'] ?? 'Unknown';
              final imageUrl = locationData['imageUrl'] ?? '';

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DetailOwner(documentId: docId),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                      16.0), // Rounded border for the whole card
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(
                                    16.0)), // Ensures top corners are rounded
                            child: Image.network(
                              imageUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                      child: Text("Failed to load image")),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Parking Location ${index + 1}",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(), // Pushes "Car Slots" to the right
                                  Text(
                                    "Car Slots: 0/$carSlot",
                                    style: const TextStyle(
                                      fontSize: 16,
                                     fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Location: $locationName",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Divider(),
                              Text(
                                    "Status : online",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

// Widget parkLocation() {
//   User? currentUser = FirebaseAuth.instance.currentUser;
//   String ownerId = currentUser?.uid ?? '';

//   return StreamBuilder<QuerySnapshot>(
//     stream: FirebaseFirestore.instance
//         .collection('parking')
//         .where('ownerId', isEqualTo: ownerId)
//         .snapshots(),
//     builder: (context, snapshot) {
//       if (snapshot.connectionState == ConnectionState.waiting) {
//         return const Center(child: CircularProgressIndicator());
//       }
//       if (snapshot.hasError) {
//         return const Center(
//           child: Text(
//             'Error loading locations',
//             style: TextStyle(fontSize: 18, color: Colors.red),
//           ),
//         );
//       }
//       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//         return const Center(
//           child: Text(
//             'No parking locations available',
//             style: TextStyle(fontSize: 18, color: Colors.grey),
//           ),
//         );
//       }

//       final locations = snapshot.data!.docs;

//       return ListView.builder(
//         itemCount: locations.length,
//         itemBuilder: (context, index) {
//           final locationData = locations[index].data() as Map<String, dynamic>?;
//           final docId = locations[index].id;

//           if (locationData == null) {
//             return const SizedBox.shrink();
//           }

//           final locationName = locationData['nameparking'] ?? 'Unknown Location';
//           final address = locationData['address'] ?? 'Unknown Address';
//           final description = locationData['description'] ?? 'No Description Available';
//           final price = locationData['price'] ?? 'Unknown';
//           final carSlot = locationData['car_slot'] ?? 'Unknown';
//           final imageUrl = locationData['imageUrl'] ?? '';

//           return GestureDetector(
//             onTap: () {
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (context) => btnLocation(documentId: docId),
//                 ),
//               );
//             },
//             child: Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16.0),
//               ),
//               elevation: 6,
//               margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           "Parking Location ${index + 1}",
//                           style: const TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         PopupMenuButton<String>(
//                           onSelected: (value) {
//                             if (value == 'edit') {
//                               _showEditLocationDialog(docId: docId, data: locationData);
//                             } else if (value == 'delete') {
//                               _showDeleteConfirmationDialog(docId: docId);
//                             }
//                           },
//                           itemBuilder: (BuildContext context) => [
//                             const PopupMenuItem(value: 'edit', child: Text('Edit')),
//                             const PopupMenuItem(value: 'delete', child: Text('Delete')),
//                           ],
//                           icon: const Icon(Icons.more_vert),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     if (imageUrl.isNotEmpty)
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(12),
//                         child: Image.network(
//                           imageUrl,
//                           height: 150,
//                           width: double.infinity,
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) =>
//                               const Center(child: Text("Failed to load image")),
//                         ),
//                       ),
//                     const SizedBox(height: 12),
//                     Text("Location: $locationName", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
//                     const SizedBox(height: 8),
//                     Text("Address: $address", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
//                     const SizedBox(height: 8),
//                     Text("Car Slots: 0/$carSlot", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
//                     const SizedBox(height: 8),
//                     Text("Price: $price", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
//                     const SizedBox(height: 12),
//                     ElevatedButton.icon(
//                       icon: const Icon(Icons.map, color: Colors.white),
//                       label: const Text("Open in Maps", style: TextStyle(color: Colors.white)),
//                       onPressed: () {
//                         Navigator.of(context).push(MaterialPageRoute(
//                           builder: (c) => map_api(documentId: docId),
//                         ));
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blueAccent,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     },
//   );
// }

  /// Function to show an edit popup dialog (remains unchanged)
  void _showEditLocationDialog({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final _editFormKey = GlobalKey<FormState>();
    final _editNameController =
        TextEditingController(text: data['nameparking'] ?? '');
    final _editAddressController =
        TextEditingController(text: data['address'] ?? '');
    final _editDescriptionController =
        TextEditingController(text: data['description'] ?? '');
    final _editPriceController =
        TextEditingController(text: data['price']?.toString() ?? '');
    final _editCarSlotController =
        TextEditingController(text: data['car_slot']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Row(
            children: const [
              Icon(Icons.edit, color: Colors.blue, size: 30),
              SizedBox(width: 8),
              Text(
                "Edit Location",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _editFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Location Name
                  TextFormField(
                    controller: _editNameController,
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
                  // Address
                  TextFormField(
                    controller: _editAddressController,
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
                  // Description
                  TextFormField(
                    controller: _editDescriptionController,
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
                  // Price
                  TextFormField(
                    controller: _editPriceController,
                    decoration: InputDecoration(
                      labelText: "Price",
                      prefixIcon:
                          const Icon(Icons.attach_money, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter the price";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Car Slots
                  TextFormField(
                    controller: _editCarSlotController,
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
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: () async {
                if (_editFormKey.currentState?.validate() ?? false) {
                  await FirebaseFirestore.instance
                      .collection('parking')
                      .doc(docId)
                      .update({
                    'nameparking': _editNameController.text.trim(),
                    'address': _editAddressController.text.trim(),
                    'description': _editDescriptionController.text.trim(),
                    'price': int.parse(_editPriceController.text.trim()),
                    'car_slot': int.parse(_editCarSlotController.text.trim()),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Location updated successfully!')),
                  );
                }
              },
              child: const Text(
                "Save",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Function to show a delete confirmation dialog.
  void _showDeleteConfirmationDialog({required String docId}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this location?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('parking')
                    .doc(docId)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Location deleted successfully!")),
                );
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
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
            const SizedBox(height: 14),
            buttonthree(context),
            const SizedBox(height: 14),
            const Text(
              'Parking location',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => emp_register()),
                          (route) => false, // Removes all previous routes
                        );
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
