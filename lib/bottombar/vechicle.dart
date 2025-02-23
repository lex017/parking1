import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parking1/data_save/addvechicle.dart';
import 'package:parking1/data_save/licenseplate.dart';
import 'package:parking1/vechicle/detailcar.dart';

class Vechicle extends StatefulWidget {
  const Vechicle({super.key});

  @override
  State<Vechicle> createState() => _VehicleState();
}

class _VehicleState extends State<Vechicle> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Placeholder data for demonstration
  final String ownerName = 'Owner'; // Replace with actual data if needed
  final String licensePlate = '123ABC'; // Replace with actual data if needed
  final String selectedCity = 'City'; // Replace with actual data if needed

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
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  "Error fetching data",
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No vehicle data found",
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            final vehicles = snapshot.data!.docs;

            return ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index].data() as Map<String, dynamic>;

                // Fetch imageUrl
                final imageUrl = vehicle['imageUrl'] ?? '';

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Brand: ${vehicle['brandName'] ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Color: ${vehicle['color'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Plate: ${vehicle['plate'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12.0),

                        // Display the image using the URL from Cloudinary
                        if (imageUrl.isNotEmpty)
                          Image.network(
                            imageUrl,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        else
                          const SizedBox(
                              height: 150, child: Text('No image available')),

                        const SizedBox(height: 12.0),
                        ElevatedButton(
                          onPressed: () {
                            final documentId = vehicles[index]
                                .id; // Get the document ID from Firestore
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailCar(documentId: documentId),
                              ),
                            );
                          },
                          child: const Text('View Details'),
                        ),
                      ],
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
