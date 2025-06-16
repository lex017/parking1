import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:parking1/cash/QrPay.dart';
import 'package:parking1/chose/comment.dart';
import 'package:parking1/map_api/selectdetail.dart';

class btnLocation extends StatefulWidget {
  final String documentId;

  const btnLocation({required this.documentId, super.key});

  @override
  State<btnLocation> createState() => _BtnLocationState();
}

class _BtnLocationState extends State<btnLocation> {
  int availableSlots = 0;
  bool isFavorite = false;
  int checkedInCount = 0;

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

  /// Fetches the count of 'check-in' vehicles for this location
  Stream<int> getCheckedInCount() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('locationId', isEqualTo: widget.documentId)
        .where('Status', whereIn: ['check-in', 'pending'])
        // .where('parkingStatus', isEqualTo: 'check-in')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  void _showFullDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.all(20),
        actionsPadding: EdgeInsets.only(bottom: 10, right: 10),
        title: Column(
          children: [
            Lottie.network(
              'https://lottie.host/ee106baf-cfce-452b-8650-fb6fc4f50d82/npLBQIImO9.json', // Make sure to add a relevant Lottie file in your assets
              height: 120,
              width: 120,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 10),
            Text(
              "Parking Full",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        content: Text(
          "Sorry, all parking slots are currently occupied. Please check back later.",
          style: TextStyle(fontSize: 16, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        actions: [
          Align(
            alignment: Alignment.center,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
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
                    .collection('parking')
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
                      height: 300,
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
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),

          // Information section
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('parking')
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
                final nameLocation = data['nameparking'] ?? 'Unknown Name';
                final description =
                    data['description'] ?? 'No description available';

                final landmark = data['landmark'] ?? 'None';
                final opentime = data['openTime'] ?? 'none';
                final closetime = data['closeTime'] ?? 'none';
                final carSlot = data['car_slot'] ?? 0;
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              nameLocation,
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.comment,
                                color: Colors.black, size: 30),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        Comment(documentId: widget.documentId),
                                  ));
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      
                      // Real-time Check-in Counter
                      StreamBuilder<int>(
                        stream: getCheckedInCount(),
                        builder: (context, snapshot) {
                          checkedInCount = snapshot.data ?? 0;

                          return Text(
                            "Car Slot: $checkedInCount/$availableSlots",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 10,),
                      Row(
                        children: [
                          Icon(Icons.access_time_sharp,
                              color: Colors.black, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            opentime,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            closetime,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: Colors.grey,
                            ),
                          ),
                        ],
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

                      const SizedBox(height: 20),
                      Text(
                        'Nearby places',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        landmark,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.grey,
                        ),
                      ),
                      
                      const SizedBox(height: 15),

                      const Spacer(),

                      SizedBox(
                        width: 500,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (checkedInCount >= availableSlots)
                              ? null
                              : () {
                                  if (checkedInCount >= availableSlots) {
                                    _showFullDialog(context);
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => detailPay(
                                            documentId: widget.documentId),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (checkedInCount == availableSlots)
                                ? Colors.red
                                : Colors.blue,
                          ),
                          child: Text(
                            (checkedInCount >= availableSlots)
                                ? "Sold Out"
                                : "Booking",
                            style: const TextStyle(
                                fontSize: 18, color: Colors.white),
                          ),
                        ),
                      )
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
