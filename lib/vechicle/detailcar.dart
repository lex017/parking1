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
  bool hasError = false; // Track error state
  bool isTimeout = false; // Track timeout state

  final Map<String, Map<String, Color>> plateColors = {
    "ລັດບໍລິຫານ": {"background": Colors.blue, "text": Colors.white, "border": Colors.white},
    "ເອກະຊົນລາວ": {"background": Colors.yellow, "text": Colors.black, "border": Colors.black},
    "ບໍລິສັດ/ທຸລະກິດ 100%": {"background": Colors.white, "text": Colors.black, "border": Colors.black},
    "ບໍລິສັດ/ທຸລະກິດ 1%": {"background": Colors.white, "text": Colors.blue, "border": Colors.blue},
    "ເອກະຊົນຕ່າງດ້າວ": {"background": Colors.yellow, "text": Colors.lightBlue, "border": Colors.blue},
    "ອົງການຈັດຕັ້ງສາກົນ(ນຳໃຊ້ສ່ວນຕົວ)": {"background": Colors.white, "text": Colors.lightBlue, "border": Colors.cyan},
  };

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true); // Enable Firestore caching
    _fetchCarDetails();
  }

  Future<void> _fetchCarDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.documentId)
          .get()
          .timeout(const Duration(seconds: 10)); // Timeout after 10 seconds

      if (doc.exists) {
        setState(() {
          carData = doc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vehicle not found")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        isTimeout = true;
        isLoading = false;
      });
      print("Error or timeout: $e");
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

    if (isTimeout) {
      return const Scaffold(
        body: Center(child: Text("The request timed out. Please try again later.")),
      );
    }

    if (hasError) {
      return const Scaffold(
        body: Center(child: Text("Something went wrong. Please try again later.")),
      );
    }

    final plateType = carData?["selectedplate"] ?? "Unknown"; // Handling null plateType
    final plateColor = plateColors[plateType] ?? {
      "background": Colors.grey,
      "text": Colors.white,
      "border": Colors.grey
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Car Details"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: plateColor["background"],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: plateColor["border"] ?? Colors.transparent, // Set border color
                    width: 2, // Border width
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      carData?["selectedCity"] ?? "Unknown",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: plateColor["text"],
                      ),
                    ),
                    Text(
                      carData?["plate"] ?? "Unknown",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: plateColor["text"],
                      ),
                    ),
                    Text(
                      plateType,
                      style: TextStyle(
                        fontSize: 18,
                        color: plateColor["text"],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildDetailRow("Brand", carData?["brandName"] ?? "Unknown"),
            _buildDetailRow("Color", carData?["color"] ?? "Unknown"),
            _buildDetailRow("License Plate", carData?["plate"] ?? "Unknown"),
            _buildDetailRow("City Plate", carData?["selectedCity"] ?? "Unknown"),
            _buildDetailRow("Plate Type", carData?["selectedplate"] ?? "Unknown"),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  var updatedData = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditCar(
                          documentId: widget.documentId, carData: carData!),
                    ),
                  );
                  if (updatedData != null) {
                    setState(() {
                      carData = updatedData; // Update data after editing
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text("Edit Car"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
