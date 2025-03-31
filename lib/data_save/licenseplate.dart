import 'package:flutter/material.dart';
import 'package:parking1/data_save/platecolor.dart';

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
      appBar: AppBar(
        title: const Text("Select province"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: cities.length,
                itemBuilder: (context, index) {
                  final city = cities[index];

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedCity == city ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(
                        city,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: selectedCity == city ? Colors.white : Colors.black,
                        ),
                      ),
                      trailing: selectedCity == city
                          ? const Icon(Icons.check_circle, color: Colors.white)
                          : const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                      onTap: () {
                        setState(() {
                          selectedCity = city;
                        });

                        // Navigate to the addVechicle screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => Platetype(selectedCity: selectedCity!),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
