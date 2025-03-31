import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:parking1/cash/QrPay.dart';
import 'package:parking1/chose/comment.dart';
import 'package:parking1/detailownner/detail_map.dart';
import 'package:parking1/detailownner/detail_review.dart';
import 'package:parking1/detailownner/edit_employee.dart';

class DetailOwner extends StatefulWidget {
  final String documentId;

  const DetailOwner({required this.documentId, super.key});

  @override
  State<DetailOwner> createState() => _DetailOwnerState();
}

class _DetailOwnerState extends State<DetailOwner> {
  int availableSlots = 0;
  int checkedInCount = 0;

  /// Fetches the count of 'check-in' vehicles for this location
  Stream<int> getCheckedInCount() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('locationId', isEqualTo: widget.documentId)
        .where('Status', whereIn: ['check-in', 'pending'])
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
        contentPadding: const EdgeInsets.all(20),
        actionsPadding: const EdgeInsets.only(bottom: 10, right: 10),
        title: Column(
          children: [
            Lottie.network(
              'https://lottie.host/ee106baf-cfce-452b-8650-fb6fc4f50d82/npLBQIImO9.json',
              height: 120,
              width: 120,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 10),
            const Text(
              "Parking Full",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        content: const Text(
          "Sorry, all parking slots are currently occupied. Please check back later.",
          style: TextStyle(fontSize: 16, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(fontSize: 16)),
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
                        child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      !snapshot.data!.exists) {
                    return const SizedBox(
                      height: 300,
                      child: Center(
                          child: Text("No image available",
                              style: TextStyle(color: Colors.grey))),
                    );
                  }
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final imageUrl = data['imageUrl'] ?? '';

                  return Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      image: imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(imageUrl), fit: BoxFit.cover)
                          : null,
                      color: Colors.grey.shade200,
                    ),
                    child: imageUrl.isEmpty
                        ? const Center(
                            child: Text("No image available",
                                style: TextStyle(color: Colors.grey)))
                        : null,
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
                  onPressed: () => Navigator.of(context).pop(),
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
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!.exists) {
                  return const Center(
                      child: Text("No data available",
                          style: TextStyle(color: Colors.grey)));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final nameLocation = data['nameparking'] ?? 'Unknown Name';
                final address = data['address'] ?? 'No description available';
                final tag = data['tag'] ?? 'None';
                availableSlots = data['car_slot'] ?? 0;

                return Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, -4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(nameLocation,
                                style: const TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.fmd_good_sharp,
                                color: Colors.black, size: 30),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Comment(
                                          documentId: widget.documentId)));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(address,
                          style: const TextStyle(
                              fontSize: 16, height: 1.6, color: Colors.grey)),
                      const SizedBox(height: 20),

                      // Real-time Check-in Counter
                      // StreamBuilder<int>(
                      //   stream: getCheckedInCount(),
                      //   builder: (context, snapshot) {
                      //     checkedInCount = snapshot.data ?? 0;
                      //     return Text(
                      //       "Car Slot: $checkedInCount/$availableSlots",
                      //       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      //     );
                      //   },
                      // ),

                      const SizedBox(height: 20),
                      DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            const TabBar(
                              isScrollable: true,
                              labelStyle: TextStyle(fontSize: 21),
                              unselectedLabelStyle: TextStyle(fontSize: 18),
                              labelColor: Colors.blue, // Color for selected tab
                              unselectedLabelColor:
                                  Colors.grey, // Color for unselected tabs
                              indicatorColor: Colors.blue, // Indicator color
                              indicatorWeight:
                                  3.0, // Thickness of the indicator
                              tabs: [
                                Tab(text: "Detail"),
                                Tab(text: "Employee"),
                                Tab(text: "Review"),
                              ],
                            ),
                            SizedBox(
                              height: 460, // Adjust as needed
                              child: TabBarView(
                                children: [
                                  Center(
                                      child: DetailMap(
                                          documentId: widget.documentId)),
                                  Center(
                                      child: EditEmployee()),
                                  Center(child: DetailReview()),
                                ],
                              ),
                            ),
                          ],
                        ),
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
