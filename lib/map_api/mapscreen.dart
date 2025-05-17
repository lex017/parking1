import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  final String documentId;
  const MapScreen({required this.documentId, Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _markerPosition;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    fetchLocation();
  }

  Future<void> fetchLocation() async {
    final doc = await FirebaseFirestore.instance
        .collection('parking')
        .doc(widget.documentId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final GeoPoint? geoPoint = data['location']; // หรือใช้ 'latitude' & 'longitude' หากคุณเก็บแยก

      if (geoPoint != null) {
        setState(() {
          _markerPosition = LatLng(geoPoint.latitude, geoPoint.longitude);
          _markers.add(
            Marker(
              markerId: MarkerId('parking_marker'),
              position: _markerPosition!,
              infoWindow: InfoWindow(title: "Location of parking"),
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map')),
      body: _markerPosition == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _markerPosition!,
                zoom: 16,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
    );
  }
}