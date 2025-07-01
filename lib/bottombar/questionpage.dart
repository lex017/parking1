import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final TextEditingController _reasonController = TextEditingController();
  String _selectedTopic = 'Ticket Rejected';

  final List<String> _topics = [
    'Ticket Rejected',
    'Payment Rejected',
    'Other',
  ];

  void _submitQuestion() async {
    final reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your reason.')),
      );
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('Reports').add({
        'userId': userId,
        'topic': _selectedTopic,
        'description': reason,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Submitted successfully')),
      );

      _reasonController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 4,
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 240, 247, 255)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Topic',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(blurRadius: 4, color: Colors.black12)
                ],
              ),
              child: DropdownButton<String>(
                value: _selectedTopic,
                isExpanded: true,
                underline: const SizedBox(),
                onChanged: (value) {
                  setState(() {
                    _selectedTopic = value!;
                  });
                },
                items: _topics.map((topic) {
                  return DropdownMenuItem(
                    value: topic,
                    child: Text(topic),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Describe your issue',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter your explanation here...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _submitQuestion,
                icon: const Icon(Icons.send),
                label: const Text('Submit'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.blueAccent,
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
