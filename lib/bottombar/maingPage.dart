import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:parking1/map_api/LocationPage.dart';
import 'package:parking1/menu/Help.dart';
import 'package:parking1/menu/Wallet.dart';
import 'package:parking1/menu/history.dart';


class mainPage extends StatefulWidget {
  const mainPage({super.key});

  @override
  State<mainPage> createState() => _MainPageState();
}

class _MainPageState extends State<mainPage> {
  final auth = FirebaseAuth.instance;
  final String cloudinaryApiUrl = "https://api.cloudinary.com/v1_1/doiq3nkso/resources/image";

  List<String> adImages = [
                           'https://res.cloudinary.com/doiq3nkso/image/upload/v1736348080/sivz7kpn9yhcajh6r0mb.jpg',
                           'https://res.cloudinary.com/doiq3nkso/image/upload/v1736348049/ojs7n8aufknyoerqfxex.jpg',
                           'https://res.cloudinary.com/doiq3nkso/image/upload/v1736348850/jwufyzc7imcwz3ylpi5d.png'
                          ]; 

  @override
  void initState() {
    super.initState();
    fetchAdImages();
  }

  /// Fetch ad images from Cloudinary
  Future<void> fetchAdImages() async {
    try {
      // Replace with your Cloudinary API Key and Secret.
      const cloudinaryApiKey = "432378133179461";
      const cloudinaryApiSecret = "J7PLX9YnL1aT64A02nS1LcSSv00";
      const folder = "public_upload"; // Replace with your Cloudinary folder.

      final authHeader = "Basic " + base64Encode(utf8.encode("$cloudinaryApiKey:$cloudinaryApiSecret"));

      final response = await http.get(
        Uri.parse('$cloudinaryApiUrl?prefix=$folder'),
        headers: {"Authorization": authHeader},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List resources = data['resources'] ?? [];
        final List<String> fetchedUrls = resources.map((item) => item['secure_url'] as String).toList();

        setState(() {
          adImages = fetchedUrls;
        });
      } else {
        print("Failed to fetch images: ${response.body}");
      }
    } catch (e) {
      print("Error fetching images: $e");
    }
  }

  Widget adSlider() {
    if (adImages.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: adImages.length,
        itemBuilder: (context, index) {
          return adCard(
            imageUrl: adImages[index],
          );
        },
      ),
    );
  }

  Widget adCard({
    required String imageUrl,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            'assets/images/placeholder.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget nameProfile() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(auth.currentUser?.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text(
              'Error loading profile',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
          );
        } else {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final username = userData['username'] ?? 'Guest';
          final location = userData['location'] ?? 'Unknown';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              title: Text(
                username,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Location: $location'),
            ),
          );
        }
      },
    );
  }

  Widget dashboardSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          dashboardButton(
            icon: Icons.location_on_outlined,
            label: 'Location',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => LocationPage()),
              );
            },
          ),
          dashboardButton(
            icon: Icons.history,
            label: 'History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => history()),
              );
            },
          ),
          dashboardButton(
            icon: Icons.wallet,
            label: 'Wallet',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => Wallet()),
              );
            },
          ),
          dashboardButton(
            icon: Icons.help,
            label: 'Help',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => Help()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget dashboardButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          margin: EdgeInsets.zero,
          child: Container(
            width: 120,
            height: 140,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: Colors.blue,
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            nameProfile(),
            adSlider(),
            const SizedBox(height: 24),
            const Text(
              'Features',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            dashboardSection(),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: mainPage(),
  ));
}
