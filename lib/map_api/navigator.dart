import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class navigate extends StatefulWidget {
  const navigate({super.key});

  @override
  State<navigate> createState() => _NavigateState();
}

class _NavigateState extends State<navigate> {
  double? destinationLat;
  double? destinationLng;

  @override
  void initState() {
    super.initState();
    _fetchDestination();
  }

  Future<void> _fetchDestination() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('locations')
          .doc('destination') // Replace with your document ID
          .get();

      if (snapshot.exists) {
        GeoPoint geoPoint = snapshot['location'];
        setState(() {
          destinationLat = geoPoint.latitude;
          destinationLng = geoPoint.longitude;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch location: $e")),
      );
    }
  }

  void _launchGoogleMaps() async {
    if (destinationLat != null && destinationLng != null) {
      String googleMapsUrl =
          "https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng&travelmode=driving";

      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Google Maps.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Destination not available.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("navigate to Destination")),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.navigation),
          label: const Text("navigate"),
          onPressed: destinationLat != null && destinationLng != null
              ? _launchGoogleMaps
              : null,
        ),
      ),
    );
  }
}
