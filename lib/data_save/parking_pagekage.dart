import 'package:flutter/material.dart';

class ParkingPagekage extends StatefulWidget {
  const ParkingPagekage({super.key});

  @override
  State<ParkingPagekage> createState() => _ParkingPagekageState();
}

class _ParkingPagekageState extends State<ParkingPagekage> {
  String selectedPackage = "1 Month";
  TextEditingController customMonthsController = TextEditingController();
  TextEditingController carSlotController = TextEditingController(text: "10");

  final Map<String, Map<String, dynamic>> packageDetails = {
    "1 Month": {
      "discount": 0,
      "price": 10000,
      "payPercent": 30,
      "perDay": 45000,
      "total": 1390000
    },
    "3 Month 25%": {
      "discount": 25,
      "price": 10000,
      "payPercent": 30,
      "perDay": 33750,
      "total": 3037500
    },
    "6 Month 20%": {
      "discount": 20,
      "price": 10000,
      "payPercent": 30,
      "perDay": 36000,
      "total": 6480000
    },
    "Custom": {
      "discount": 0,
      "price": 10000,
      "payPercent": 30,
      "perDay": 45000,
      "total": 0
    },
  };

  @override
  Widget build(BuildContext context) {
    final detail = packageDetails[selectedPackage]!;
    int months = int.tryParse(customMonthsController.text) ?? 1;
    int slots = int.tryParse(carSlotController.text) ?? 10;
    num totalCustom = months * detail['perDay'] * slots;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Package slot_car',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPackageButton("1 Month"),
            _buildPackageButton("3 Month 25%"),
            _buildPackageButton("6 Month 20%"),
            _buildPackageButton("Custom", isCustom: true),
            const SizedBox(height: 16),
            if (selectedPackage == "Custom") ...[
              TextField(
                controller: customMonthsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Enter number of months",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: carSlotController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Enter car slots (min 10)",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  int? val = int.tryParse(value);
                  if (val != null && val < 10) {
                    carSlotController.text = '10';
                    carSlotController.selection = TextSelection.fromPosition(
                        TextPosition(offset: carSlotController.text.length));
                  }
                },
              ),
            ],
            const SizedBox(height: 16),
            _buildDetailBox(detail, months, slots, totalCustom),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                // handle Next action
              },
              child: const Text("Next"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPackageButton(String label, {bool isCustom = false}) {
    bool isSelected = selectedPackage == label;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          side: BorderSide(color: Colors.blue),
          elevation: isCustom ? 4 : 0,
          minimumSize: const Size.fromHeight(45),
        ),
        onPressed: () {
          setState(() {
            selectedPackage = label;
          });
        },
        child: Text(label),
      ),
    );
  }

  Widget _buildDetailBox(Map<String, dynamic> detail, int months, int slots, num totalCustom) {
    String totalText = selectedPackage == "Custom"
        ? "${totalCustom.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} kip"
        : "${detail['total'].toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} kip";

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Slot:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Text(selectedPackage == "Custom" ? "$slots" : "15"),
              const Spacer(),
              const Text("10/less", style: TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text("Price ${detail['price']} kip"),
          Text("Pay ${detail['payPercent']}%"),
          Text("Per day ${detail['perDay']} kip"),
          Text(selectedPackage == "Custom" ? "$months Month(s)" : selectedPackage),
          const Divider(),
          Text("Total $totalText"),
        ],
      ),
    );
  }
}
