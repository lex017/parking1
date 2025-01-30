import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // For geocoding
import 'package:cloud_firestore/cloud_firestore.dart';

class MapApi extends StatefulWidget {
  const MapApi({Key? key}) : super(key: key);

  @override
  State<MapApi> createState() => _MapApiState();
}

class _MapApiState extends State<MapApi> {
  late GoogleMapController _mapController;
  LatLng _initialPosition = const LatLng(17.972937, 102.621275); // Default location
  LatLng? _currentPosition;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Determine the current location
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return;
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permissions are denied.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permissions are permanently denied.")),
      );
      return;
    }

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _markers = {
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: "You are here"),
        ),
      };
    });

    // Move camera to current position
    if (_mapController != null && _currentPosition != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(_currentPosition!),
      );
    }
  }

  // Save parking location and address to Firebase
  Future<void> _saveParkingLocation() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No location selected.")),
      );
      return;
    }

    // Get the address from the current position
    List<Placemark> placemarks = await placemarkFromCoordinates(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    Placemark place = placemarks[0];
    String address = "${place.name}, ${place.locality}, ${place.country}";

    // Save to Firebase
    FirebaseFirestore.instance.collection('parking_locations').add({
      "location": GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
      "address": address,
      "timestamp": FieldValue.serverTimestamp(),
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Parking location saved!")),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save location.")),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map for Flutter Web')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 13,
        ),
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        myLocationEnabled: true, // Enable blue dot for user's location
        myLocationButtonEnabled: true, // Enable button to center on user's location
        onTap: (LatLng position) {
          setState(() {
            _markers.add(
              Marker(
                markerId: const MarkerId("parkingLocation"),
                position: position,
                infoWindow: const InfoWindow(title: "Parking spot"),
              ),
            );
            _currentPosition = position;
          });
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _determinePosition,
            child: const Icon(Icons.location_searching),
            tooltip: 'Get Current Location',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _saveParkingLocation,
            child: const Icon(Icons.save),
            tooltip: 'Save Parking Location',
          ),
        ],
      ),
    );
  }
}
