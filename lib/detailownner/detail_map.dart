import 'package:cloud_firestore/cloud_firestore.dart';
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
      final tag = data['tag'];
      final descriptionData = data['description'];

      if (tag != null && tag is String && tag.isNotEmpty) {
        setState(() {
          categories = [tag];
        });
      }

      if (descriptionData != null && descriptionData is String) {
        setState(() {
          description = descriptionData;
        });
      }
    }
  }

  void navigateToEditScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Selectslot(documentId: widget.documentId,),
      ),
    );
  }

  void showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete this parking spot?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close the dialog
            child: Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: deleteParkingSpot,
            child: Text("Delete", style: TextStyle(color: Colors.red)),
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

      Navigator.pop(context); // Close the dialog
      Navigator.pop(context); // Go back after deletion

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Parking spot deleted successfully!")),
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    SizedBox(height: 15),
                    Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // To prevent overflow
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: navigateToEditScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Edit',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            TextButton(
              onPressed: showDeleteConfirmationDialog,
              child: Text(
                "Delete",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                  decorationColor:
                      Colors.red, // Match underline color with text
                  decorationThickness:
                      2, // Increase thickness for better visibility
           // Creates a gap between text and underline
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
