import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parking1/data_save/qr_parking.dart';
import 'package:parking1/data_save/qr_sub.dart';

class SubscriptionPackage extends StatefulWidget {
  final String name;
  final int price;
  final String parkingId;

  const SubscriptionPackage({
    super.key,
    required this.name,
    required this.price, required this.parkingId,
  });

  @override
  State<SubscriptionPackage> createState() => _ParkingPagekageState();
}

class _ParkingPagekageState extends State<SubscriptionPackage> {
  String selectedPackage = "1 Month";
  TextEditingController customMonthsController = TextEditingController();
  TextEditingController carSlotController = TextEditingController();
  String? carSlotError;

  late final Map<String, Map<String, dynamic>> packageDetails;

  @override
  void initState() {
    super.initState();
    packageDetails = {
      "1 Month": {
        "months": 1,
        "payPercent": 30,
      },
      "3 Month 25%": {
        "months": 3,
        "payPercent": 25,
      },
      "6 Month 20%": {
        "months": 6,
        "payPercent": 20,
      },
      "Custom": {
        "months": 1, // default, can be overwritten
        "payPercent": 30,
      },
    };
  }

  Map<String, num> calculatePrice({
    required Map<String, dynamic> detail,
    required int months,
    required int slots,
  }) {
    double payPercent = (detail['payPercent'] ?? 0).toDouble() / 100;
    int price = widget.price;

    double perDay = price * payPercent * slots;
    double perMonth = perDay * 30;
    double totalPrice = perMonth * months;

    return {
      'perDay': perDay,
      'perMonth': perMonth,
      'totalPrice': totalPrice,
    };
  }

  @override
  Widget build(BuildContext context) {
    final detail = packageDetails[selectedPackage]!;
    int months = selectedPackage == "Custom"
        ? (int.tryParse(customMonthsController.text) ?? 1)
        : detail['months'];
    int slots = int.tryParse(carSlotController.text) ?? 10;

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
              'Package Slot Car',
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
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
            ],
            _buildDetailBox(detail, months, slots),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                final detail = packageDetails[selectedPackage]!;
                int months = selectedPackage == "Custom"
                    ? (int.tryParse(customMonthsController.text) ?? 1)
                    : detail['months'];
                int slots = int.tryParse(carSlotController.text) ?? 10;

                if (slots < 10) {
                  setState(() {
                    carSlotError = "Minimum slot is 10";
                  });
                  return;
                }

                final priceInfo = calculatePrice(
                    detail: detail, months: months, slots: slots);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QrSub(
                      name: widget.name,
                      slots: slots,
                      months: months,
                      packageType: selectedPackage,
                      price:widget.price,
                      pricePerDay: priceInfo['perDay'],
                      pricePerMonth: priceInfo['perMonth'],
                      totalPrice: priceInfo['totalPrice'],
                      parkingId: widget.parkingId,
                    ),
                  ),
                );
              },
              child: Text("Next",style: TextStyle(color: Colors.white),),
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
          side: const BorderSide(color: Colors.blue),
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

  Widget _buildDetailBox(Map<String, dynamic> detail, int months, int slots) {
    final priceInfo =
        calculatePrice(detail: detail, months: months, slots: slots);

    String perDayText =
        "${priceInfo['perDay']!.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} kip";
    String perMonthText =
        "${priceInfo['perMonth']!.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} kip";
    String totalPriceText =
        "${priceInfo['totalPrice']!.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} kip";

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
              const Text("Slot:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Text(slots.toString()),
            ],
          ),
          const SizedBox(height: 8),
          Text("Price per Day: $perDayText"),
          Text("Price per Month: $perMonthText"),
          Text(selectedPackage == "Custom"
              ? "$months Month(s)"
              : selectedPackage),
          const Divider(),
          Text("Total Price: $totalPriceText"),
        ],
      ),
    );
  }
}
