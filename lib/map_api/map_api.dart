import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:parking1/map_api/btnlocation.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;



class map_api extends StatefulWidget {
  final String documentId;
  const map_api({Key? key, required this.documentId}) : super(key: key);

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
    final BitmapDescriptor customMe = await resizeIcon('assets/images/pin.png', 120); // Adjust width as needed
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
          icon: customMe,
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
  Future<BitmapDescriptor> resizeIcon(String assetPath, int width) async {
  final ByteData data = await rootBundle.load(assetPath);
  final Uint8List bytes = data.buffer.asUint8List();

  final ui.Codec codec = await ui.instantiateImageCodec(bytes, targetWidth: width);
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  final ByteData? resizedData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(resizedData!.buffer.asUint8List());
}

  Future<void> _loadMarkersFromFirebase() async {
  final BitmapDescriptor customIcon = await resizeIcon('assets/images/car.png', 80); // Adjust width as needed

  FirebaseFirestore.instance.collection('parking').snapshots().listen((snapshot) {
    Set<Marker> newMarkers = snapshot.docs
        .map((doc) {
          GeoPoint? geoPoint = doc['location'];
          String address = doc['address'] ?? "Unknown Location";

          if (geoPoint != null) {
            return Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(geoPoint.latitude, geoPoint.longitude),
              icon: customIcon, // Set resized icon
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
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),
          SlidingUpPanel(
            backdropColor: Colors.white,
            controller: _panelController,
            minHeight: 0,
            maxHeight: 480,
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
  /// Fetches the count of 'check-in' vehicles for this location
  Stream<int> getCheckedInCount() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('locationId', isEqualTo: docId)
        .where('Status', isEqualTo: 'check-in')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance.collection('parking').doc(docId).get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
        return const Center(child: Text("Error loading location details"));
      }

      final data = snapshot.data!.data() as Map<String, dynamic>;
      final locationName = data['nameparking'] ?? 'Unknown Location';
      final addressName = data['address'] ?? 'Unknown Address';
      final price = data['price'] ?? 'Unknown Price';
      final carSlot = data['car_slot'] ?? 0;
      final imageUrl = data['imageUrl'] ?? '';

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location name
                Text(
                  locationName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: Theme.of(context).cardColor,
),
                ),
                const SizedBox(height: 12),
                // Display image with rounded corners
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                // Address and price row
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 20, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        addressName,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 20, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      "$price kip",
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Real-time Check-in Counter
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 20, color: Colors.green),
                    const SizedBox(width: 6),
                    StreamBuilder<int>(
                      stream: getCheckedInCount(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text("Loading check-ins...",
                              style: TextStyle(fontSize: 16, color: Colors.black87));
                        }
                        return Text(
                          "Car Slot: ${snapshot.data}/$carSlot",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
               
                // Next button aligned to the right
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.map,color: Colors.white,),
                      label: const Text("Next",style: TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => btnLocation(documentId: docId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}}
