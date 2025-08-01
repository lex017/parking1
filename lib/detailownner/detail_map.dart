import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:parking1/detailownner/edit_map.dart';
import 'package:parking1/detailownner/selectslot.dart';

class DetailMap extends StatefulWidget {
  final String documentId;

  const DetailMap({required this.documentId, super.key});

  @override
  State<DetailMap> createState() => _DetailMapState();
}

class _DetailMapState extends State<DetailMap> {
  List<String> categories = [];
  String description = '';
  String price = '';
  String opentime = '';
  String closetime = '';

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('parking')
        .doc(widget.documentId)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;

      // รับค่า tag เป็น String หรือ List<String> ก็ได้ (ปรับได้ตามข้อมูลจริง)
      final tag = data['tag'];
      final priceData = data['price'];
      final descriptionData = data['description'];
      final opentimeData = data['openTime'];
      final closetimeData = data['closeTime'];

      setState(() {
        if (tag != null) {
          if (tag is String && tag.isNotEmpty) {
            categories = [tag];
          } else if (tag is List) {
            categories = List<String>.from(tag);
          }
        }
        if (descriptionData != null && descriptionData is String) {
          description = descriptionData;
        }
        if (priceData != null) {
          price = priceData.toString();
        }
        if (opentimeData != null) {
          opentime = opentimeData.toString();
        }
        if (closetimeData != null) {
          closetime = closetimeData.toString();
        }
      });
    }
  }

  void navigateToEditScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Selectslot(documentId: widget.documentId),
      ),
    );
  }

  void showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content:
            const Text("Are you sure you want to delete this parking spot?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close the dialog
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              await deleteParkingSpot();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> deleteParkingSpot() async {
    try {
      await FirebaseFirestore.instance
          .collection('parking')
          .doc(widget.documentId)
          .delete();

      Navigator.pop(context); // Go back after deletion

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Parking spot deleted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete parking spot: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                    "Ev_support".tr(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10,),
                  if (categories.isNotEmpty)
                    Wrap(
                      spacing: 8.0,
                      children: categories.map((category) {
                        return Container(
                          height: 40,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 16),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 10),
                 
                  const SizedBox(height: 8),
                  Text(
                    description.isEmpty
                        ? "No description available"
                        : description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    thickness: 1,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/kip.png',
                        width: 18,
                        height: 18,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Price".tr(),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        "Open_time".tr(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        opentime,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled,
                          color: Colors.redAccent, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        "Close_time".tr(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        closetime,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ป้องกัน overflow
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: navigateToEditScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:  Text(
                  'Edit'.tr(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TextButton(
              onPressed: showDeleteConfirmationDialog,
              child:  Text(
                "Delete".tr(),
                style: TextStyle(
                  color: const Color.fromARGB(255, 47, 41, 40),
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.red,
                  decorationThickness: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
