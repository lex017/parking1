import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerPage extends StatefulWidget {
  @override
  _MapPickerPageState createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng _pickedLocation = LatLng(13.7563, 100.5018); // Default: Bangkok
  GoogleMapController? _mapController;
  String _address = 'Move the map to choose a location';

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _pickedLocation = position.target;
    });
  }

  void _onCameraIdle() async {
    setState(() {
      _address = 'Loading address...';
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _pickedLocation.latitude,
        _pickedLocation.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _address =
              '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Unable to get address';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pick Location')),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _pickedLocation,
              zoom: 15,
            ),
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),

          // Center marker icon
          Center(
            child: Icon(Icons.location_pin, size: 50, color: Colors.red),
          ),

          // Bottom UI
          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 6,
                        color: Colors.black12,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                  child: Text(
                    _address,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, {
                      'lat': _pickedLocation.latitude,
                      'lng': _pickedLocation.longitude,
                      'address': _address,
                    });
                  },
                  icon: Icon(Icons.check_circle),
                  label: Text('Select this location',style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
