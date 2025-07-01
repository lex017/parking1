import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  late GoogleMapController mapController;
  LatLng? currentPosition;
  LatLng parkingLocation = const LatLng(17.968855, 102.605599); // เปลี่ยนตำแหน่งจอดรถตามจริง
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
      markers.add(Marker(
          markerId: const MarkerId('user'),
          position: currentPosition!,
          infoWindow: const InfoWindow(title: 'ตำแหน่งของคุณ')));
      markers.add(Marker(
          markerId: const MarkerId('parking'),
          position: parkingLocation,
          infoWindow: const InfoWindow(title: 'ที่จอดรถ')));
    });
    _getRoute();
  }

  Future<void> _getRoute() async {
  if (currentPosition == null) return;

 String apiKey = 'AIzaSyDOQ6K3wivSzz-EdHLrdxy7QTcnzk_FOuQ'; // แค่ key พอ
 // ✅ อย่ามีพ่วง query string
  String url =
      'https://maps.googleapis.com/maps/api/directions/json?origin=${currentPosition!.latitude},${currentPosition!.longitude}&destination=${parkingLocation.latitude},${parkingLocation.longitude}&key=$apiKey';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['routes'].isNotEmpty) {
      final points = data['routes'][0]['overview_polyline']['points'];
      final routeCoords = _decodePolyline(points);

      setState(() {
        polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            color: Colors.blue,
            width: 5,
            points: routeCoords,
          ),
        );
      });
    } else {
      print("No routes found");
    }
  } else {
    print("Direction API Error: ${response.body}");
  }
}


  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('นำทางไปยังที่จอดรถ'),
      ),
      body: currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentPosition!,
                zoom: 16,
              ),
              onMapCreated: (controller) {
                mapController = controller;
              },
              markers: markers,
              polylines: polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
    );
  }
}
