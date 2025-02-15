import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Comment extends StatefulWidget {
  final String documentId; // Document ID from Locations
  const Comment({required this.documentId, super.key});

  @override
  State<Comment> createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to add a comment with username and documentId
  Future<void> _addComment() async {
    final user = _auth.currentUser;
    if (user != null && _commentController.text.isNotEmpty) {
      try {
        // Fetch username from Firestore (assumes a "users" collection with a "username" field)
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        String username = userDoc.exists ? (userDoc['username'] ?? 'Unknown') : 'Unknown';

        // Add comment with username and documentId (from Locations)
        await _firestore.collection('comments').add({
          'text': _commentController.text,
          'userId': user.uid,
          'username': username, // Store username
          'documentId': widget.documentId, // Associate comment with a specific location
          'createdAt': Timestamp.now(),
        });

        _commentController.clear();
        print("Comment added successfully!"); // Debugging log
      } catch (e) {
        print("Error adding comment: $e");
      }
    } else {
      print("User is null or comment is empty");
    }
  }

  // Stream to fetch comments only for the specific document (location)
  Stream<List<Map<String, dynamic>>> _getComments() {
    if (widget.documentId.isEmpty) {
      print("Error: documentId is empty!");
      return const Stream.empty(); // Avoid querying with empty documentId
    }

    return _firestore
        .collection('comments')
        .where('documentId', isEqualTo: widget.documentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print("Fetched ${snapshot.docs.length} comments for documentId: ${widget.documentId}");

      if (snapshot.docs.isEmpty) {
        print("No comments found for this documentId.");
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        print("Comment Data: $data"); // Print each comment for debugging

        return {
          'id': doc.id,
          'text': data['text'] ?? "No Text",
          'username': data['username'] ?? "Unknown",
          'createdAt': data['createdAt'] ?? Timestamp.now(),
        };
      }).toList();
    });
  }

  // Function to delete the location and its associated comments
  Future<void> _deleteLocationAndComments() async {
    try {
      // Start a batch operation
      WriteBatch batch = _firestore.batch();

      // Delete location
      DocumentReference locationRef = _firestore.collection('locations').doc(widget.documentId);
      batch.delete(locationRef);

      // Delete all comments associated with the location
      QuerySnapshot commentsSnapshot = await _firestore
          .collection('comments')
          .where('documentId', isEqualTo: widget.documentId)
          .get();

      for (var commentDoc in commentsSnapshot.docs) {
        batch.delete(commentDoc.reference); // Delete each associated comment
      }

      // Commit the batch operation
      await batch.commit();
      print("Location and comments deleted successfully!");
    } catch (e) {
      print("Error deleting location and comments: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteLocationAndComments, // Call delete function
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input Field and Submit Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue, size: 30),
                  onPressed: _addComment,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Comment List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getComments(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print("Stream error: ${snapshot.error}");
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    print("No comments found for this location.");
                    return const Center(child: Text('No comments yet!'));
                  }

                  final comments = snapshot.data!;
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          title: Text(comment['text']),
                          subtitle: Text("By: ${comment['username']}"),
                          trailing: Text(_formatTimestamp(comment['createdAt'])),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Format timestamp to a readable string
  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return "${dateTime.hour}:${dateTime.minute} - ${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }
}
