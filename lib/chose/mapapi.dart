import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? _selectedAddress;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? selectedDocId; // Added this variable

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

  Future<void> _loadMarkersFromFirebase() async {
    FirebaseFirestore.instance.collection('Locations').snapshots().listen((snapshot) {
      Set<Marker> newMarkers = snapshot.docs.map((doc) {
        if (doc.data().containsKey('location')) {
          GeoPoint geoPoint = doc['location'];
          String address = doc['address'] ?? "Unknown Location";

          return Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(geoPoint.latitude, geoPoint.longitude),
            infoWindow: InfoWindow(title: address),
            onTap: () {
              setState(() {
                selectedDocId = doc.id;
              });
              // If you are using _panelController, make sure it's initialized
              // _panelController.open();
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
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
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
        "location": GeoPoint(_centerMarkerPosition.latitude, _centerMarkerPosition.longitude),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Parking Location')),
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
            markers: _markers, // Fixed: Set markers
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Center(
            child: const Icon(
              Icons.location_on,
              size: 40,
              color: Colors.red,
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Text(
                      _currentAddress,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      child: const Text("Save Location"),
                    ),
                  ],
                ),
              ),
            ),
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
        ],
      ),
    );
  }
}
