import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  final String bookingId;
  final String? initialMessage; // <-- New field for prefilled message

  const ChatPage({Key? key, required this.bookingId, this.initialMessage}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late TextEditingController _messageController; // late because initialized in initState
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  String _userId = '';
  String _userName = 'User';
  final String _adminId = 'admin';

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.initialMessage ?? '');
    _loadUserData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      _userId = user.uid;
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(user.uid).get();
      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _userName = data['username'] ?? 'User';
        });
      }
    }
  }

  String getChatId() {
    List<String> ids = [_userId, _adminId];
    ids.sort();
    return ids.join('_');
  }

  Future<void> _sendMessage() async {
    String text = _messageController.text.trim();
    if (text.isEmpty) return;

    String chatId = getChatId();

    await _firestore.collection('chats').doc(chatId).set({
      'userId': _userId,
      'adminId': _adminId,
      'lastMessage': text,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'text': text,
      'senderId': _userId,
      'timestamp': FieldValue.serverTimestamp(),
      'bookingId': widget.bookingId,
    });

    _messageController.clear();
  }

  Future<void> _sendImageMessage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);

    const String cloudName = "doiq3nkso";
    const String uploadPreset = "parking";

    String url = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

    var request = http.MultipartRequest("POST", Uri.parse(url));
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseBody);

      if (jsonResponse['secure_url'] != null) {
        String downloadUrl = jsonResponse['secure_url'];
        String chatId = getChatId();

        await _firestore.collection('chats').doc(chatId).set({
          'userId': _userId,
          'adminId': _adminId,
          'lastMessage': '[Image]',
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _firestore.collection('chats').doc(chatId).collection('messages').add({
          'text': '',
          'imageUrl': downloadUrl,
          'senderId': _userId,
          'timestamp': FieldValue.serverTimestamp(),
          'bookingId': widget.bookingId,
        });
      } else {
        print("Cloudinary upload failed: ${jsonResponse['error']['message']}");
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isMe = data['senderId'] == _userId;
    Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
    DateTime date = timestamp.toDate();

    return ChatMessage(
      text: data['text'] ?? '',
      isMe: isMe,
      timestamp: date,
      imageUrl: data['imageUrl'],
    );
  }

  @override
  Widget build(BuildContext context) {
    String chatId = getChatId();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Admin'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No messages yet."));
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) =>
                        _buildMessageItem(snapshot.data!.docs[index]),
                  );
                },
              ),
            ),
            const Divider(height: 1.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 5.0, spreadRadius: 1.0),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: _sendImageMessage,
                    color: Colors.blue,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String? imageUrl;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                child: Text('Ad'),
                backgroundColor: Colors.grey,
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[200] : Colors.grey[300],
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 5.0, spreadRadius: 1.0),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          imageUrl!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: const TextStyle(fontSize: 16),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                child: const Text('Me'),
                backgroundColor: Colors.blue[200],
              ),
            ),
        ],
      ),
    );
  }
}
