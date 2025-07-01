import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:parking1/detailownner/detail_map.dart';
import 'package:parking1/detailownner/detail_review.dart';
import 'package:parking1/detailownner/edit_employee.dart';
import 'package:parking1/map_api/mapscreen.dart';

class DetailOwner extends StatefulWidget {
  final String documentId;
  const DetailOwner({required this.documentId, super.key});

  @override
  State<DetailOwner> createState() => _DetailOwnerState();
}

class _DetailOwnerState extends State<DetailOwner> {
  int availableSlots = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            // ส่วนรูปภาพ
            Stack(
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('parking')
                      .doc(widget.documentId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const SizedBox(
                        height: 250,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final imageUrl = data['imageUrl'] ?? '';

                    return Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: imageUrl != ''
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: Colors.grey[300],
                      ),
                      child: imageUrl == ''
                          ? const Center(child: Text("No image"))
                          : null,
                    );
                  },
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              ],
            ),

            // ส่วนข้อมูลสถานที่
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('parking')
                  .doc(widget.documentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text("No data")),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final name = data['nameparking'] ?? 'Unknown';
                final address = data['address'] ?? 'No address';
                availableSlots = data['car_slot'] ?? 0;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(address,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fmd_good_sharp),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MapScreen(documentId: widget.documentId),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            // แท็บเลือก
            const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: "Detail"),
                Tab(text: "Employee"),
                Tab(text: "Review"),
              ],
            ),

            // เนื้อหาแต่ละแท็บขยายเต็มพื้นที่ที่เหลือ
            Expanded(
              child: TabBarView(
                children: [
                  DetailMap(documentId: widget.documentId),
                  EditEmployee(locationId: widget.documentId),
                  DetailReview(parkingId: widget.documentId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
