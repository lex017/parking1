import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditCar extends StatefulWidget {
  final String documentId; // Car Document ID
  final Map<String, dynamic> carData; // Existing Car Data

  const EditCar({super.key, required this.documentId, required this.carData});

  @override
  State<EditCar> createState() => _EditCarState();
}

class _EditCarState extends State<EditCar> {
  late TextEditingController brandController;
  late TextEditingController colorController;
  late TextEditingController plateController;

  @override
  void initState() {
    super.initState();
    brandController = TextEditingController(text: widget.carData["brandName"]);
    colorController = TextEditingController(text: widget.carData["color"]);
    plateController = TextEditingController(text: widget.carData["plate"]);
  }

  Future<void> _updateCarDetails() async {
    try {
      await FirebaseFirestore.instance.collection('vehicles').doc(widget.documentId).update({
        "brandName": brandController.text,
        "color": colorController.text,
        "plate": plateController.text,
        "timestamp": FieldValue.serverTimestamp(),
      });

      // Return updated data to DetailCar page
      Navigator.pop(context, {
        "brandName": brandController.text,
        "color": colorController.text,
        "plate": plateController.text,
        "imageUrl": widget.carData["imageUrl"], // Keep the same image
      });
    } catch (e) {
      print("Error updating car details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update details")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Car Details"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: brandController,
              decoration: const InputDecoration(labelText: "Brand Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: colorController,
              decoration: const InputDecoration(labelText: "Color"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: plateController,
              decoration: const InputDecoration(labelText: "License Plate"),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _updateCarDetails,
                child: const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
