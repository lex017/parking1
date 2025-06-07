import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
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
        const SnackBar(
            content: Text("Location permissions are permanently denied.")),
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
      Set<Marker> newMarkers = snapshot.docs
          .map((doc) {
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
          })
          .whereType<Marker>()
          .toSet();

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
          // Google Map
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
          // Central Pin with shadow
          Center(
            child: Container(
             
              child: Image.asset(
                'assets/images/pin.png',
                width: 48,
                height: 48,
              ),
            ),
          ),
          // Glassmorphism Bottom Card
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.7),
                        Colors.blue.withOpacity(0.2)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentAddress,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => BtnaddParking(
                              address: _currentAddress,
                              latitude: _centerMarkerPosition.latitude,
                              longitude: _centerMarkerPosition.longitude,
                            ),
                          ));
                        },
                        icon: const Icon(Icons.save_alt, color: Colors.white),
                        label: const Text("Save Location",style: TextStyle(color: Colors.white),),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // My Location Button
          Positioned(
            bottom: 780,
            left: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _determinePosition,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
          // Zoom Controls
          Positioned(
            top: 700,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
                    onPressed: _zoomIn,
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.blue),
                    onPressed: _zoomOut,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}