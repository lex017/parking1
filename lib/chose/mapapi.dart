import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:parking1/data_save/btnadd_parking.dart';

class MapApi extends StatefulWidget {
  const MapApi({Key? key}) : super(key: key);

  @override
  State<MapApi> createState() => _MapApiState();
}

class _MapApiState extends State<MapApi> {
  late GoogleMapController _mapController;
  LatLng _centerMarkerPosition = const LatLng(17.972937, 102.621275);
  String _currentAddress = "Move the map to select location";
  Set<Marker> _markers = {};
  String? selectedDocId;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _loadMarkersFromFirebase();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
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

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _centerMarkerPosition = LatLng(position.latitude, position.longitude);
    });

    _mapController.animateCamera(
      CameraUpdate.newLatLng(_centerMarkerPosition),
    );

    _getAddressFromLatLng(_centerMarkerPosition);
  }

  Future<BitmapDescriptor> resizeIcon(String assetPath, int width) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec =
        await ui.instantiateImageCodec(bytes, targetWidth: width);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? resizedData =
        await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(resizedData!.buffer.asUint8List());
  }

  Future<void> _loadMarkersFromFirebase() async {
    final customIcon = await resizeIcon('assets/images/car.png', 80);
    FirebaseFirestore.instance
        .collection('parking')
        .snapshots()
        .listen((snapshot) {
      Set<Marker> newMarkers = snapshot.docs.map((doc) {
        if (doc.data().containsKey('location')) {
          GeoPoint geoPoint = doc['location'];
          String address = doc['address'] ?? "Unknown Location";
          return Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(geoPoint.latitude, geoPoint.longitude),
            icon: customIcon,
            infoWindow: InfoWindow(title: address),
            onTap: () {
              setState(() {
                selectedDocId = doc.id;
              });
            },
          );
        }
        return null;
      }).whereType<Marker>().toSet();

      setState(() {
        _markers.clear();
        _markers.addAll(newMarkers);
      });
    });
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.first;
      String address = "${place.name}, ${place.locality}, ${place.country}";
      setState(() {
        _currentAddress = address;
      });
    } catch (e) {
      setState(() {
        _currentAddress = "Unable to get address";
      });
    }
  }

  Future<void> _saveParkingLocation() async {
    try {
      await FirebaseFirestore.instance.collection('parking_locations').add({
        "location": GeoPoint(
            _centerMarkerPosition.latitude, _centerMarkerPosition.longitude),
        "address": _currentAddress,
        "timestamp": FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Parking location saved successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save location: $e")),
      );
    }
  }

  // Zoom in and Zoom out methods
  Future<void> _zoomIn() async {
    final currentZoom = await _mapController.getZoomLevel();
    _mapController.animateCamera(CameraUpdate.zoomTo(currentZoom + 1));
  }

  Future<void> _zoomOut() async {
    final currentZoom = await _mapController.getZoomLevel();
    _mapController.animateCamera(CameraUpdate.zoomTo(currentZoom - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // Transparent AppBar with bold title
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Select Parking Location',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _centerMarkerPosition,
              zoom: 14,
            ),
            onMapCreated: (GoogleMapController controller) {
              setState(() {
                _mapController = controller;
              });
            },
            onCameraMove: (CameraPosition position) {
              setState(() {
                _centerMarkerPosition = position.target;
              });
            },
            onCameraIdle: () {
              _getAddressFromLatLng(_centerMarkerPosition);
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          // Central Pin with Shadow
          Center(
            child: Container(
              
              child: Image.asset(
                'assets/images/pin.png',
                width: 40,
                height: 40,
              ),
            ),
          ),
          // Glassmorphism Bottom Card for Address & Save Button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentAddress,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => BtnaddParking(
                              address: _currentAddress,
                              latitude: _centerMarkerPosition.latitude,
                              longitude: _centerMarkerPosition.longitude,
                            ),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text("Save Location"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Floating Button for My Location
          Positioned(
            top: 40,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _determinePosition,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
          // Zoom Controls (Zoom In and Zoom Out)
          Positioned(
            bottom: 100,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
