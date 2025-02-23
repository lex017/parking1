import 'package:flutter/material.dart';
import 'package:parking1/data_save/addVechicle.dart';
import 'package:parking1/data_save/platecolor.dart'; // Import addVechicle screen

class LicensePlate extends StatefulWidget {
  const LicensePlate({super.key});
  

  @override
  State<LicensePlate> createState() => _LicensePlateState();
}

class _LicensePlateState extends State<LicensePlate> {
  String? selectedCity; // Store selected city

  final List<String> cities = [
    "ແຂວງຄໍາມ່ວນ",
    "ແຂວງຈໍາປາສັກ",
    "ແຂວງຊຽງຂວາງ",
    "ແຂວງໄຊຍະບູລີ",
    "ແຂວງໄຊສົມບູນ",
    "ແຂວງເຊກອງ",
    "ແຂວງບໍລິຄໍາໄຊ",
    "ແຂວງບໍ່ແກ້ວ",
    "ແຂວງຜົ້ງສາລີ",
    "ແຂວງວຽງຈັນ",
    "ແຂວງສາລະວັນ",
    "ແຂວງສະຫວັນນະເຂດ",
    "ແຂວງຫຼວງນ້ຳທາ",
    "ແຂວງຫຼວງພະບາງ",
    "ແຂວງຫົວພັນ",
    "ແຂວງອັດຕະປື",
    "ແຂວງອຸດົມໄຊ",
    "ນະຄອນຫຼວງວຽງຈັນ",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select a City")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Choose Your City",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: cities.map((city) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCity = city;
                        });

                        // Navigate to the addVechicle screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => Platetype(
                              selectedCity:selectedCity!
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: selectedCity == city ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedCity == city ? Colors.blueAccent : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            city,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: selectedCity == city ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}