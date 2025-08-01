import 'package:easy_localization/easy_localization.dart';
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
    "ນະຄອນຫຼວງວຽງຈັນ",
    "ຄໍາມ່ວນ",
    "ຈໍາປາສັກ",
    "ຊຽງຂວາງ",
    "ໄຊຍະບູລີ",
    "ໄຊສົມບູນ",
    "ເຊກອງ",
    "ບໍລິຄໍາໄຊ",
    "ບໍ່ແກ້ວ",
    "ຜົ້ງສາລີ",
    "ວຽງຈັນ",
    "ສາລະວັນ",
    "ສະຫວັນນະເຂດ",
    "ຫຼວງນ້ຳທາ",
    "ຫຼວງພະບາງ",
    "ຫົວພັນ",
    "ອັດຕະປື",
    "ອຸດົມໄຊ",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select_province".tr()),
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
