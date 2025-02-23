import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  String? selectedPlateType;

  final TextEditingController brandNameController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController nameplateController = TextEditingController();
  final TextEditingController plateController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";

  bool isLoading = false;

  
  // Save vehicle data to Firestore
  Future<void> _savePaymentData() async {
  setState(() {
    isLoading = true;
  });


  if (brandNameController.text.isEmpty ||
      colorController.text.isEmpty ||
      nameplateController.text.isEmpty ||
      plateController.text.isEmpty ||
      nameController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill out all fields")),
    );
    setState(() {
      isLoading = false;
    });
    return;
  }

 

  // await Future.delayed(const Duration(seconds: 3));

  // Create a custom documentId like car1_234 using the owner's name and plate number
  String documentId = "car1_${plateController.text}";  // Example: car1_234

  FirebaseFirestore.instance.collection('vehicles').doc(documentId).set({
    "brandName": brandNameController.text,
    "color": colorController.text,
    "nameplace": nameplateController.text,
    "plate": plateController.text,
    "selectedCity": widget.selectedCity,
    "selectedplate": widget.selectedcolor,
    "timestamp": FieldValue.serverTimestamp(),
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
        backgroundColor: Colors.blue,
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
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 20),
                  // Display the selected city
                  Text(
                    "Selected Plate: ${widget.selectedcolor}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: brandNameController,
                    decoration: InputDecoration(
                      labelText: "Brand Name",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: colorController,
                    decoration: InputDecoration(
                      labelText: "Color",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: nameplateController,
                    decoration: InputDecoration(
                      labelText: "NamePlate",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: plateController,
                    decoration: InputDecoration(
                      labelText: "Plate",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Owner's Name",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
               
                  const SizedBox(height: 40),

                  Center(
                    child: ElevatedButton(
                      onPressed: _savePaymentData,
                      child: const Text("Save Vehicle Info"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
