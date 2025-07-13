import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parking1/data_save/licenseplate.dart';
import 'package:parking1/vechicle/detailcar.dart';

// Vehicle class to represent vehicle data
class Vehicle {
  final String brandName;
  final String color;
  final String plate;
  final String documentId;
  final String userId;

  Vehicle({
    required this.brandName,
    required this.color,
    required this.plate,
    required this.documentId,
    required this.userId,
  });

  factory Vehicle.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Vehicle(
      brandName: data['brandName'] ?? 'Unknown',
      color: data['color'] ?? 'Unknown',
      plate: data['numberplate'] ?? 'Unknown',
      documentId: doc.id,
      userId: data['userId'] ?? '',
    );
  }
}

class Vechicle extends StatefulWidget {
  const Vechicle({super.key});

  @override
  State<Vechicle> createState() => _VehicleState();
}

class _VehicleState extends State<Vechicle> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser ;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Vehicle Information")),
        body: const Center(child: Text("Please log in to see your vehicles.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
  title: const Text(
    "Vehicle Information",
    style: TextStyle(
      color: Colors.white, // Change text color here
      fontSize: 20, // Optional: Adjust font size
      fontWeight: FontWeight.bold, // Optional: Adjust font weight
    ),
  ),
  centerTitle: true,
  backgroundColor: Colors.blueAccent,
),

      body: Container(
        color: Theme.of(context).cardColor, // Background color
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('vehicles')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error fetching data: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.car_repair, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "No vehicle data found",
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                  ],
                ),
              );
            }

            final vehicles = snapshot.data!.docs
                .map((doc) => Vehicle.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
                .toList();

            return ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 8,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailCar(
                            documentId: vehicle.documentId,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.directions_car, color: Colors.blueAccent),
                              const SizedBox(width: 8.0),
                              Text(
                                '${vehicle.brandName}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Icon(Icons.color_lens, color: Colors.blueAccent),
                              const SizedBox(width: 8.0),
                              Text(
                                'Color: ${vehicle.color}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Icon(Icons.confirmation_number, color: Colors.blueAccent),
                              const SizedBox(width: 8.0),
                              Text(
                                'License Plate: ${vehicle.plate}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => LicensePlate()),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).cardColor,
      ),
    );
  }
}