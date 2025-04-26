import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parking1/drawer.dart';
import 'package:parking1/map_api/btnlocation.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String searchQuery = '';
  String? selectedCategory = 'All'; // Default to 'All'

  // Sample categories for filtering
  final List<String> categories = ['All', 'EV'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Location"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          // Single Selection Chips for filtering
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              // Ensures alignment to the left
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8.0,
                alignment:
                    WrapAlignment.start, // Aligns chips to the start (left)
                children: categories.map((category) {
                  return ChoiceChip(
                    label: Text(category),
                    selected: selectedCategory == category,
                    onSelected: (bool selected) {
                      setState(() {
                        selectedCategory = selected ? category : 'All';
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('parking').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Error fetching data",
                        style: TextStyle(color: Colors.red)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No locations found",
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                final locations = snapshot.data!.docs.where((doc) {
                  final location = doc.data() as Map<String, dynamic>;
                  final name = location['nameparking']?.toLowerCase() ?? '';
                  final category = location['tag'] ??
                      ''; // Assuming category field exists in Firestore

                  bool matchesSearch = name.contains(searchQuery);
                  bool matchesCategory = (selectedCategory == 'All') ||
                      (selectedCategory == 'EV' && category == 'EV');

                  return matchesSearch && matchesCategory;
                }).toList();

                if (locations.isEmpty) {
                  return const Center(
                    child: Text("No matching locations",
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final location =
                        locations[index].data() as Map<String, dynamic>;
                    final documentId = locations[index].id; // Get document ID

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  btnLocation(documentId: documentId),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          elevation: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (location['imageUrl'] != null &&
                                  location['imageUrl'].isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16.0),
                                    topRight: Radius.circular(16.0),
                                  ),
                                  child: Image.network(
                                    location['imageUrl'],
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Text("Failed to load image",
                                            style:
                                                TextStyle(color: Colors.red)),
                                      );
                                    },
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            location['nameparking'] ??
                                                'Unknown Name',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            location['address'] ??
                                                'Unknown Address',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        StreamBuilder<int>(
                                          stream: FirebaseFirestore.instance
                                              .collection('bookings')
                                               .where('locationId', isEqualTo: documentId)
                                              .where('Status', whereIn: ['check-in', 'pending']) // Assuming 'check-in' status means the car is occupying a slot
                                              .snapshots()
                                              .map((snapshot) => snapshot.docs
                                                  .length), // Count the number of checked-in cars
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Center(
                                                  child:
                                                      CircularProgressIndicator());
                                            }

                                            if (snapshot.hasError) {
                                              return const Center(
                                                  child: Text(
                                                      'Error fetching checked-in data'));
                                            }

                                            final checkedInCount = snapshot
                                                    .data ??
                                                0; // Number of cars occupying slots
                                            final totalSlots = location[
                                                    'car_slot'] ??
                                                0; // Total car slots available

                                            return Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Text(
                                                "CAR: $checkedInCount/$totalSlots", // Display checked-in cars out of total slots
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
