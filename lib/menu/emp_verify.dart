import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class EmpVerify extends StatefulWidget {
  final String paymentId;
  final String locationId;
  const EmpVerify(
      {super.key, required this.paymentId, required this.locationId});

  @override
  State<EmpVerify> createState() => _EmpVerifyState();
}

class _EmpVerifyState extends State<EmpVerify> {
  final auth = FirebaseAuth.instance;
  late Stream<String> _realTimeDateStream;
  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  late String locationId = widget.locationId;

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

  Widget nameProfile() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .doc(widget.paymentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
          final username = userData['userName'] ?? 'Guest';
          final profileImageUrl = userData['profileImage'] ?? '';

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : const AssetImage('assets/default_profile.png')
                            as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Name: $username",
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(
                        height: 3,
                      ),
                      Text("For verify....",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
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
            pendingPayment(),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget pendingPayment() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .doc(widget.paymentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return const Text('No pending Payment');
        }

        var payment = snapshot.data!;
        var data = payment.data() as Map<String, dynamic>;
        String? imageUrl = data['imageBill'];

        if (data['status'] != 'pending' ||
            data['locationId'] != widget.locationId) {
          return const Text('No pending Payment');
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Payment ID: ${payment.id}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Date: ${data['date'] ?? 'N/A'}",
                        style: const TextStyle(fontSize: 17)),
                    Text("Time: ${data['time'] ?? 'N/A'}",
                        style: const TextStyle(fontSize: 17)),
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context)
                        .style
                        .copyWith(fontSize: 20),
                    children: [
                      const TextSpan(
                          text: "Amount: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                        text: "${data['amount'] ?? 'N/A'}",
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (imageUrl != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              leading: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                              title: const Text("Zoom Bill Image"),
                            ),
                            body: Center(
                              child: InteractiveViewer(
                                child: Image.network(imageUrl),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        height: 350,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  const Text("No bill image provided"),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      _buildVerify(payment),
                      const SizedBox(height: 12),
                      _buildReject(payment),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerify(DocumentSnapshot payment) {
    return Column(
      children: [
        SizedBox(
          width: 250, // Full width for responsiveness
          height: 50, // Height of the button
          child: ElevatedButton(
            onPressed: () async {
              // Update the payment status in Firestore
              await FirebaseFirestore.instance
                  .collection('payments')
                  .doc(payment.id)
                  .update({'status': 'success'});

              // Also update the payment status in the bookings collection
              await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(payment[
                      'bookingId']) // Assuming bookingId is a field in payment document
                  .update({'paymentStatus': 'success'});

              // Show confirmation message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment Verified')),
              );

              // Pop this screen after a slight delay so the SnackBar shows
              Future.delayed(const Duration(milliseconds: 300), () {
                Navigator.pop(context);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // Set background color to green
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12), // Adjust the radius as needed
              ),
            ),
            child: Text(
              'Verify',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20), // Set text color to white and adjust font size
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReject(DocumentSnapshot payment) {
    return Column(
      children: [
        SizedBox(
          width: 250, // Full width for responsiveness
          height: 50, // Height of the button
          child: ElevatedButton(
            onPressed: () async {
              // Update the payment status in Firestore
              await FirebaseFirestore.instance
                  .collection('payments')
                  .doc(payment.id)
                  .update({'status': 'reject'});

              // Also update the payment status in the bookings collection
              await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(payment[
                      'bookingId']) // Assuming bookingId is a field in payment document
                  .update({'paymentStatus': 'reject'});

              // Show confirmation message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment Rejected')),
              );

              // Pop this screen after a slight delay so the SnackBar shows
              Future.delayed(const Duration(milliseconds: 300), () {
                Navigator.pop(context);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Set background color to red
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12), // Adjust the radius as needed
              ),
            ),
            child: Text(
              'Reject',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20), // Set text color to white and adjust font size
            ),
          ),
        ),
      ],
    );
  }
}
