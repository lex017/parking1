import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:parking1/bottombar/vechicle.dart';

class AddVechicle extends StatefulWidget {
  final String ownerName;
  final String selectedCity;
  final String licensePlate;
  final String selectedcolor;

  const AddVechicle({
    required this.ownerName,
    required this.selectedCity,
    required this.licensePlate,
    required this.selectedcolor,
    super.key,
  });

  @override
  State<AddVechicle> createState() => _VechicleState();
}

class _VechicleState extends State<AddVechicle> {
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Get Firebase Auth instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController brandNameController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController nameplateController = TextEditingController();
  final TextEditingController plateController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool isLoading = false;

  Future<void> _savePaymentData() async {
    setState(() {
      isLoading = true;
    });

    // Get the logged-in user's UID
    User? user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (brandNameController.text.isEmpty ||
        colorController.text.isEmpty ||
        nameplateController.text.isEmpty ||
        plateController.text.isEmpty ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill out all fields")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    String documentId = "car1_${plateController.text}"; // Example: car1_123

    // Save data to Firestore with user's UID
    await _firestore.collection('vehicles').doc(documentId).set({
      "brandName": brandNameController.text,
      "color": colorController.text,
      "charplate": nameplateController.text,
      "numberplate": plateController.text,
      "province": widget.selectedCity,
      "typeplate": widget.selectedcolor,
      "timestamp": FieldValue.serverTimestamp(),
      "userId": user.uid, // Save the logged-in user's UID
    }).then((_) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data saved successfully!")),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Vechicle()),
      );
    }).catchError((error) {
      setState(() {
        isLoading = false;
      });
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
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Vehicle Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Display the selected city
                  Text(
                    "Selected City: ${widget.selectedCity}",
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    "Selected Plate: ${widget.selectedcolor}",
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: brandNameController,
                    decoration: InputDecoration(
                      labelText: "Brand Name",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: colorController,
                    decoration: InputDecoration(
                      labelText: "Color",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: nameplateController,
                    decoration: InputDecoration(
                      labelText: "NamePlate",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: plateController,
                    decoration: InputDecoration(
                      labelText: "Plate",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Center(
                    child: ElevatedButton(
                      onPressed: _savePaymentData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Background color
                        foregroundColor: Colors.white, // Text color
                        minimumSize: const Size(
                            double.infinity, 50), // Full width and height of 50
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30), // Rounded corners
                        ),
                      ),
                      child: const Text("Save Vehicle Info",
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
