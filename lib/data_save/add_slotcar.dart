import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'qr_addslot.dart';

class AddSlotcar extends StatefulWidget {
  final String parkingId;

  const AddSlotcar({super.key, required this.parkingId});

  @override
  State<AddSlotcar> createState() => _AddSlotcarState();
}

class _AddSlotcarState extends State<AddSlotcar> {
  TextEditingController carSlotController = TextEditingController();
  String? carSlotError;
  Map<String, num>? priceInfo;
  int remainingDays = 0;

  @override
  void initState() {
    super.initState();
  }

  Future<Map<String, num>> calculateAdditionalSlotPrice({
    required String parkingId,
    required int additionalSlots,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection('parking')
        .doc(parkingId)
        .get();

    final data = doc.data()!;
    final int price = data['price'];
    final double payPercent = (data['payPercent'] ?? 30).toDouble() / 100;
    final int packageMonths = data['packageMonths'];
    final Timestamp startTimestamp = data['packageStartDate'];
    final DateTime packageStart = startTimestamp.toDate();

    final DateTime packageEnd = DateTime(
      packageStart.year,
      packageStart.month + packageMonths,
      packageStart.day,
    );

    final DateTime today = DateTime.now();
    final int _remainingDays = packageEnd.difference(today).inDays.clamp(0, 30);

    final double perDay = price * payPercent * additionalSlots;
    final double total = perDay * _remainingDays;

    setState(() {
      remainingDays = _remainingDays;
    });

    return {
      'perDay': perDay,
      'remainingDays': _remainingDays,
      'totalPrice': total,
    };
  }

  void onSlotChanged(String value) async {
    final slots = int.tryParse(value);
    if (slots == null || slots <= 0) {
      setState(() {
        carSlotError = "Enter valid number of slots";
        priceInfo = null;
      });
      return;
    }

    final result = await calculateAdditionalSlotPrice(
      parkingId: widget.parkingId,
      additionalSlots: slots,
    );

    setState(() {
      carSlotError = null;
      priceInfo = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add More Car Slots'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Add More Slots to Current Package',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: carSlotController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Enter additional slots",
                border: const OutlineInputBorder(),
                errorText: carSlotError,
              ),
              onChanged: onSlotChanged,
            ),
            const SizedBox(height: 20),
            if (priceInfo != null) _buildPriceSummary(),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                if (priceInfo == null) return;

                final int slots = int.tryParse(carSlotController.text) ?? 0;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QrAddslot(
                      additionalSlots: slots,
                      remainingDays: remainingDays,
                      pricePerDay: priceInfo!['perDay']!,
                      totalPrice: priceInfo!['totalPrice']!, parkingId: widget.parkingId,
                    ),
                  ),
                );
              },
              child: const Text("Confirm Add Slot"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    final perDay = priceInfo!['perDay']!;
    final totalPrice = priceInfo!['totalPrice']!;

    String format(num value) => value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Remaining Days: $remainingDays"),
          const SizedBox(height: 8),
          Text("Price Per Day: ${format(perDay)} kip"),
          const Divider(),
          Text("Total to Pay: ${format(totalPrice)} kip",
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
