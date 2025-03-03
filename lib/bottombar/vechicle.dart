import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parking1/data_save/addvechicle.dart';
import 'package:parking1/data_save/licenseplate.dart';
import 'package:parking1/vechicle/detailcar.dart';

// Vehicle class to represent vehicle data
class Vehicle {
  final String brandName;
  final String color;
  final String plate;
  final String documentId; // Add documentId

  Vehicle({
    required this.brandName,
    required this.color,
    required this.plate,
    required this.documentId, // Include documentId in constructor
  });

  factory Vehicle.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data()!;
    return Vehicle(
      brandName: data['brandName'] ?? 'Unknown',
      color: data['color'] ?? 'Unknown',
      plate: data['plate'] ?? 'Unknown',
      documentId: doc.id, // Extract documentId from the snapshot
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle Information"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('vehicles').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // You can replace this with a skeleton loader
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

            final vehicles = snapshot.data!.docs.map((doc) => Vehicle.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();

            return ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 5,
                  child: InkWell( // Use InkWell for ripple effect
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
                          Text(
                            'Brand of car: ${vehicle.brandName}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Color of car: ${vehicle.color}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'License_Plate: ${vehicle.plate}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
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
        backgroundColor: Colors.white,
      ),
    );
  }
}