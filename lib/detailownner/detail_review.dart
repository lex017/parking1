import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DetailReview extends StatefulWidget {
  final String parkingId; // Parking ID to filter reviews

  const DetailReview({super.key, required this.parkingId});

  @override
  State<DetailReview> createState() => _DetailReviewState();
}

class _DetailReviewState extends State<DetailReview> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchReviews() async {
    QuerySnapshot snapshot = await _firestore
        .collection('review')
        .where('documentId', isEqualTo: widget.parkingId) // Filter by parking ID
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
    }).toList();
  }

  // Function to delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection('review').doc(reviewId).delete();
      setState(() {}); // Refresh UI after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting review: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(  
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No reviews found for this parking.'));
          } else {
            List<Map<String, dynamic>> reviews = snapshot.data!;
            return ListView.separated(
              itemCount: reviews.length,
              separatorBuilder: (context, index) => const Divider(thickness: 1, height: 1), // Adds a line
              itemBuilder: (context, index) {
                Map<String, dynamic> review = reviews[index];
                return ListTile(
                  title: Text(
                    review['username'] ?? 'Anonymous',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        review['comment'] ?? 'No comment',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: List.generate(
                          review['rating'] ?? 0,
                          (index) => const Icon(Icons.star, color: Colors.amber, size: 16),
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        deleteReview(review['id']);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert), // Three-dot menu
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
