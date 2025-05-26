import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EmpDetailpend extends StatefulWidget {
  final Map<String, dynamic> ticketData;
  final String vehicleId;
  final String locationId;
  final String bookingId;

  const EmpDetailpend(
      {Key? key, required this.ticketData, required this.vehicleId, required this.locationId, required this.bookingId})
      : super(key: key);

  @override
  _EmpDetailpendState createState() => _EmpDetailpendState();
}

class _EmpDetailpendState extends State<EmpDetailpend> {
  Map<String, dynamic>? vehicleData;
  Map<String, dynamic>? bookingData;

  @override
  void initState() {
    super.initState();
    fetchVehicleData();
    fetchBookingData();
  }

    Future<void> fetchBookingData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("bookings")
          .doc(widget.bookingId)
          .get();

      if (snapshot.exists) {
        setState(() {
          bookingData = snapshot.data();
        });
      }
    } catch (e) {
      print("Error fetching booking data: $e");
    }
  }
  Future<void> fetchVehicleData() async {
    final vehicleId = widget.ticketData["vehicleId"];
    if (vehicleId != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection("vehicles")
            .doc(vehicleId)
            .get();
        if (snapshot.exists) {
          setState(() {
            vehicleData = snapshot.data();
          });
        }
      } catch (e) {
        print("Error fetching vehicle data: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final province = widget.ticketData["province"] ?? '';
    final namePlate = widget.ticketData["namePlate"] ?? '';
    final plate = widget.ticketData["plate"] ?? '';
    final timestamp = widget.ticketData["timestamp"];
    final username= bookingData?["userName"] ?? '';
    

    final formattedTime = timestamp != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
        : '-';

    final typeplate =
        (vehicleData?["typeplate"] ?? widget.ticketData["typeplate"] ?? '')
            .toString()
            .trim();

    print("TYPEPLATE: '$typeplate'"); // Debug print

    final plateColor = _getPlateColor(typeplate);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ticket Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Plate design
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: plateColor["background"],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: plateColor["border"] ?? Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    vehicleData?["province"] ?? province,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: plateColor["text"],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        vehicleData?["charplate"] ?? namePlate,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: plateColor["text"],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        vehicleData?["numberplate"] ?? plate,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: plateColor["text"],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildInfoRow("From", "$username"),

            _buildInfoRow("Date", formattedTime),

            if (vehicleData != null) ...[
              const SizedBox(height: 20),
              const Text(
                "Vehicle Information",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),
              _buildInfoRow("Brand", vehicleData?["brandName"] ?? '-'),
              _buildInfoRow("Plate Chars", vehicleData?["charplate"] ?? '-'),
              _buildInfoRow("Plate Number", vehicleData?["numberplate"] ?? '-'),
              _buildInfoRow("Plate Type", vehicleData?["typeplate"] ?? '-'),
              _buildInfoRow("Province", vehicleData?["province"] ?? '-'),
              _buildInfoRow("Color", vehicleData?["color"] ?? '-'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getPlateColor(String typeplate) {
    switch (typeplate) {
      case "ລັດບໍລິຫານ":
        return {
          "background": Colors.blue,
          "text": Colors.white,
          "border": Colors.white,
        };
      case "ເອກະຊົນລາວ":
        return {
          "background": Colors.yellow,
          "text": Colors.black,
          "border": Colors.black,
        };
      case "ບໍລິສັດ/ທຸລະກິດ 100%":
        return {
          "background": Colors.white,
          "text": Colors.black,
          "border": Colors.black,
        };
      case "ບໍລິສັດ/ທຸລະກິດ 1%":
        return {
          "background": Colors.white,
          "text": Colors.blue,
          "border": Colors.blue,
        };
      case "ເອກະຊົນຕ່າງດ້າວ":
        return {
          "background": Colors.yellow,
          "text": Colors.lightBlue,
          "border": Colors.blue,
        };
      case "ອົງການຈັດຕັ້ງສາກົນ(ນຳໃຊ້ສ່ວນຕົວ)":
        return {
          "background": Colors.white,
          "text": Colors.lightBlue,
          "border": Colors.cyan,
        };
      default:
        return {
          "background": Colors.grey.shade300,
          "text": Colors.black,
          "border": Colors.black,
        };
    }
  }
}
