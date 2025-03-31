import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Comment extends StatefulWidget {
  final String documentId;
  const Comment({required this.documentId, super.key});

  @override
  State<Comment> createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _addComment() async {
    final user = _auth.currentUser;
    if (user != null && _commentController.text.isNotEmpty) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        String username = userDoc.exists ? (userDoc['username'] ?? 'Unknown') : 'Unknown';

        await _firestore.collection('review').add({
          'comment': _commentController.text,
          'userId': user.uid,
          'username': username,
          'documentId': widget.documentId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _commentController.clear();
      } catch (e) {
        print("❌ Error adding comment: $e");
      }
    }
  }

  Stream<List<Map<String, dynamic>>> _getComments() {
    return _firestore
        .collection('review')
        .where('documentId', isEqualTo: widget.documentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'comment': data['comment'] ?? "No Text",
          'username': data['username'] ?? "Unknown",
          'userId': data['userId'] ?? "",
          'createdAt': data['createdAt'] ?? Timestamp.now(),
        };
      }).toList();
    });
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _firestore.collection('review').doc(commentId).delete();
    } catch (e) {
      print("❌ Error deleting comment: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Review'), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getComments(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No comments yet!'));
                  }
                  final comments = snapshot.data!;
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final isOwner = user != null && user.uid == comment['userId'];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          title: Text(comment['comment']),
                          subtitle: Text("By: ${comment['username']}"),
                          trailing: isOwner
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      _deleteComment(comment['id']);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                )
                              : null,
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
}
