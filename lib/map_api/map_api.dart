import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:parking1/map_api/btnlocation.dart';

class map_api extends StatefulWidget {
  const map_api({Key? key}) : super(key: key);

  @override
  State<map_api> createState() => _MapApiState();
}

class _MapApiState extends State<map_api> {
  late GoogleMapController _mapController;
  LatLng _initialPosition = const LatLng(17.972937, 102.621275);
  final Set<Marker> _markers = {};
  LatLng? _currentPosition;
  LatLng? _searchPosition;
  String? selectedDocId;

  final PanelController _panelController = PanelController();
  double _searchRadius = 500.0;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _loadMarkersFromFirebase();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar("Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar("Location permissions are permanently denied.");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _searchPosition = _currentPosition; // Initialize search position
      _markers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: "You are here"),
        ),
      );
    });

    _mapController.animateCamera(
      CameraUpdate.newLatLng(_currentPosition!),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadMarkersFromFirebase() async {
    FirebaseFirestore.instance
        .collection('Locations')
        .snapshots()
        .listen((snapshot) {
      Set<Marker> newMarkers = snapshot.docs
          .map((doc) {
            GeoPoint? geoPoint = doc['location'];
            String address = doc['address'] ?? "Unknown Location";

            if (geoPoint != null) {
              return Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(geoPoint.latitude, geoPoint.longitude),
                infoWindow: InfoWindow(title: address),
                onTap: () {
                  setState(() {
                    selectedDocId = doc.id;
                  });
                  _panelController.open();
                },
              );
            }
            return null;
          })
          .whereType<Marker>()
          .toSet();

      setState(() {
        _markers.addAll(newMarkers);
      });
    });
  }

  void _searchInRadius() {
    if (_searchPosition == null) return;

    Set<Marker> filteredMarkers = _markers.where((marker) {
      double distance = Geolocator.distanceBetween(
        _searchPosition!.latitude,
        _searchPosition!.longitude,
        marker.position.latitude,
        marker.position.longitude,
      );
      return distance <= _searchRadius;
    }).toSet();

    setState(() {
      _markers.clear();
      _markers.addAll(filteredMarkers);
    });

    _mapController.animateCamera(
      CameraUpdate.newLatLng(_searchPosition!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map Markers')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 13,
            ),
            markers: _markers,
            circles: {
              if (_searchPosition != null)
                Circle(
                  circleId: const CircleId("searchRadius"),
                  center: _searchPosition!,
                  radius: _searchRadius,
                  fillColor: Colors.blue.withOpacity(0.2),
                  strokeColor: Colors.blue,
                  strokeWidth: 2,
                ),
            },
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),
          SlidingUpPanel(
            backdropColor: Colors.white,
            controller: _panelController,
            minHeight: 0,
            maxHeight: 370,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            panel: selectedDocId != null
                ? parkLocation(selectedDocId!)
                : const Center(child: Text("Select a parking location")),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _determinePosition,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
          Positioned(
            top: 90,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _searchInRadius,
              child: const Icon(Icons.search, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget parkLocation(String docId) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('Locations').doc(docId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return const Center(child: Text("Error loading location details"));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final locationName = data['nameLocation'] ?? 'Unknown Location';
        final addressName = data['address'] ?? 'Unknown Address';
        final price = data['price'] ?? 'Unknown Address';
        final carSlot = data['car_slot'] ?? 'Unknown';
        final imageUrl = data['imageUrl'] ?? '';

        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (imageUrl.isNotEmpty)
                  Image.network(imageUrl,
                      height: 120, width: double.infinity, fit: BoxFit.cover),
                const SizedBox(height: 20),
                Text("Address: $addressName",
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
                Text("Price: $price kip", style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
                Text("Car Slots: 0/$carSlot",
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end, // Moves button to the right
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.map),
                      label: const Text("Next"),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                btnLocation(documentId: docId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
