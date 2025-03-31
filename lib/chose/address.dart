import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class address extends StatefulWidget {
  const address({super.key});

  @override
  State<address> createState() => _addressState();
}

class _addressState extends State<address> {
  LatLng selectedPosition = const LatLng(0, 0);
  String selectedAddress = "Select an address";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Address"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Simulate address selection.
            // In practice, use your map logic to determine the selected address.
            Navigator.pop(context, {
              'address': "123 Main St, City, Country",
              'latitude': 12.3456,
              'longitude': 65.4321,
            });
          },
          child: const Text("Select This Address"),
        ),
      ),
    );
  }
}