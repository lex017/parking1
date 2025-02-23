import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editcar.dart'; // Create an edit page

class DetailCar extends StatefulWidget {
  final String documentId; // Get document ID
  
  const DetailCar({super.key, required this.documentId});

  @override
  State<DetailCar> createState() => _DetailCarState();
}

class _DetailCarState extends State<DetailCar> {
  Map<String, dynamic>? carData; // Store car data
  bool isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _fetchCarDetails();
  }

  Future<void> _fetchCarDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.documentId)
          .get();

      if (doc.exists) {
        setState(() {
          carData = doc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vehicle not found")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error fetching details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load details")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Car Details"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: carData!["imageUrl"] != null
                  ? Image.network(carData!["imageUrl"], height: 200)
                  : const Text("No Image Available"),
            ),
            const SizedBox(height: 20),
            Text("Brand: ${carData!["brandName"]}", style: const TextStyle(fontSize: 18)),
            Text("Color: ${carData!["color"]}", style: const TextStyle(fontSize: 18)),
            Text("License Plate: ${carData!["plate"]}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  var updatedData = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditCar(documentId: widget.documentId, carData: carData!),
                    ),
                  );
                  if (updatedData != null) {
                    setState(() {
                      carData = updatedData; // Update data after editing
                    });
                  }
                },
                child: const Text("Edit Car"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
