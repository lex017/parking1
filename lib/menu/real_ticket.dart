import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RealTicket extends StatefulWidget {
  final Map<String, dynamic> ticketData;
  

  const RealTicket({super.key, required this.ticketData});

  @override
  State<RealTicket> createState() => _RealTicketState();
}

class _RealTicketState extends State<RealTicket> {
  bool _isImageExpanded = false; // Track the image expansion state

  @override
  Widget build(BuildContext context) {
    final ticketData = widget.ticketData;

    final ticketId = ticketData["ticketId"] ?? '';
    final province = ticketData["province"] ?? '';
    final plateType = ticketData["plateType"] ?? '';
    final namePlate = ticketData["namePlate"] ?? '';
    final plate = ticketData["plate"] ?? '';
    final empId = ticketData["empId"] ?? '';
    final locationId = ticketData["locationId"] ?? '';
    final imageUrl = ticketData["imageUrl"];
    final status = ticketData["Status"] ?? '';
    final timestamp = ticketData["timestamp"]?.toString() ?? '';

    String qrData = '''
TicketID: $ticketId
Province: $province
PlateType: $plateType
NamePlate: $namePlate
Plate: $plate
Employee ID: $empId
Location ID: $locationId
Status: $status
Time: $timestamp
''';

    final Map<String, Map<String, Color>> plateColors = {
      "ລັດບໍລິຫານ": {
        "background": Colors.blue,
        "text": Colors.white,
        "border": Colors.white,
      },
      "ເອກະຊົນລາວ": {
        "background": Colors.yellow,
        "text": Colors.black,
        "border": Colors.black,
      },
      "ບໍລິສັດ/ທຸລະກິດ 100%": {
        "background": Colors.white,
        "text": Colors.black,
        "border": Colors.black,
      },
      "ບໍລິສັດ/ທຸລະກິດ 1%": {
        "background": Colors.white,
        "text": Colors.blue,
        "border": Colors.blue,
      },
      "ເອກະຊົນຕ່າງດ້າວ": {
        "background": Colors.yellow,
        "text": Colors.lightBlue,
        "border": Colors.blue,
      },
      "ອົງການຈັດຕັ້ງສາກົນ(ນຳໃຊ້ສ່ວນຕົວ)": {
        "background": Colors.white,
        "text": Colors.lightBlue,
        "border": Colors.cyan,
      },
    };

    final plateColor = plateColors[plateType] ?? {
      "background": Colors.grey,
      "text": Colors.white,
      "border": Colors.grey,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ticket Details"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent.shade100, Colors.blueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Ticket Details",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(thickness: 2, color: Colors.blueAccent.shade200),
                    const SizedBox(height: 10),
                    _buildInfoRow("Ticket ID", ticketId),
                    _buildInfoRow("Plate Type", plateType),
                    _buildInfoRow("Employee ID", empId),
                    _buildInfoRow("Location ID", locationId),
                    _buildInfoRow("Status", status),
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: plateColor["background"],
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: plateColor["border"] ?? Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              province,
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
                                  namePlate,
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: plateColor["text"],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  plate,
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
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isImageExpanded = !_isImageExpanded; // Toggle the image expansion state
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _isImageExpanded ? 200 : 70, // Change height based on expansion state
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrl,
                                  height: _isImageExpanded ? 200 : 70,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Center(
                                child: Text(
                                  'No Image',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "QR Code",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade400,
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200.0,
                        gapless: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}