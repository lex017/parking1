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

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _loadMarkersFromFirebase();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return;
    }

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

  Future<void> _loadMarkersFromFirebase() async {
    FirebaseFirestore.instance.collection('Locations').snapshots().listen((snapshot) {
      Set<Marker> newMarkers = snapshot.docs.map((doc) {
        GeoPoint? geoPoint = doc['location'];
        String address = doc['address'] ?? "Unknown Location";

        if (geoPoint != null) {
          return Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(geoPoint.latitude, geoPoint.longitude),
            infoWindow: InfoWindow(title: address),
            onTap: () {
              _showLocationDetails(address, geoPoint.latitude, geoPoint.longitude);
            },
          );
        }
        return null;
      }).whereType<Marker>().toSet();

      setState(() {
        _markers.addAll(newMarkers);
      });
    });
  }

  void _showLocationDetails(String address, double latitude, double longitude) {
    setState(() {
      _selectedAddress = address;
      _selectedLatitude = latitude;
      _selectedLongitude = longitude;
    });
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

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
    // Save the location to Firebase (this will trigger saving to parking_locations collection)
    await FirebaseFirestore.instance.collection('parking_locations').add({
      "location": GeoPoint(_centerMarkerPosition.latitude, _centerMarkerPosition.longitude),
      "address": _currentAddress,
      "timestamp": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Parking location saved successfully!")),
    );
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
              _mapController = controller;
            },
            onCameraMove: (CameraPosition position) {
              setState(() {
                _centerMarkerPosition = position.target;
              });
            },
            onCameraIdle: () {
              _getAddressFromLatLng(_centerMarkerPosition);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Center(
            child: Icon(
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
            top: 40,
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
