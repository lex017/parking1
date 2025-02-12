import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parking1/cash/QrPay.dart';
import 'package:parking1/chose/comment.dart';

class btnLocation extends StatefulWidget {
  final String documentId;

  const btnLocation({required this.documentId, super.key});

  @override
  State<btnLocation> createState() => _BtnLocationState();
}

class _BtnLocationState extends State<btnLocation> {
  int? selectedHours;
  int pricePerHour = 0;
  int availableSlots = 0;
  bool isFavorite = false;

  void _showImagePopup(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text(
                "Failed to load image",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              // StreamBuilder to fetch image
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Locations')
                    .doc(widget.documentId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return const SizedBox(
                      height: 300,
                      child: Center(
                        child: Text(
                          "Error loading image",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const SizedBox(
                      height: 300,
                      child: Center(
                        child: Text(
                          "No image available",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final imageUrl = data['imageUrl'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      if (imageUrl.isNotEmpty) {
                        _showImagePopup(imageUrl);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 300, // Full height for the image
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                        image: imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: Colors.grey.shade200,
                      ),
                      child: imageUrl.isEmpty
                          ? const Center(
                              child: Text(
                                "No image available",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
              // Back Button
              Positioned(
                top: 40,
                right: 16,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.comment,
                          color: Colors.white, size: 30),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Comment()),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() {
                          isFavorite = !isFavorite;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Information section
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Locations')
                  .doc(widget.documentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Error loading data",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text(
                      "No data available",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final nameLocation = data['nameLocation'] ?? 'Unknown Name';
                final description =
                    data['description'] ?? 'No description available';
                final price = data['price'] ?? 0;
                final carSlot = data['car_slot'] ?? 0;
                pricePerHour = price;
                availableSlots = carSlot;

                return Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nameLocation,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Price per hour: $pricePerHour LAK",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Car Slots: $availableSlots",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Dropdown to select hours
                      Row(
                        children: [
                          const Text(
                            "Select Hours: ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          DropdownButton<int>(
                            value: selectedHours,
                            hint: const Text("Choose"),
                            items: const [
                              DropdownMenuItem(
                                value: 2,
                                child: Text("2 Hours"),
                              ),
                              DropdownMenuItem(
                                value: 4,
                                child: Text("4 Hours"),
                              ),
                              DropdownMenuItem(
                                value: 8,
                                child: Text("8 Hours"),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedHours = value;
                              });
                            },
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Total Price and Navigate Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total Price",
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              Text(
                                "${selectedHours != null ? selectedHours! * pricePerHour : 0} LAK",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: selectedHours == null
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (c) => QrPay(),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.arrow_forward,
                                color: Colors.white),
                            label: const Text(
                              "GO",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              backgroundColor: selectedHours == null
                                  ? Colors.grey
                                  : Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
