import 'package:flutter/material.dart';
import 'package:parking1/data_save/addvechicle.dart';

class Platetype extends StatefulWidget {
  final String selectedCity;
  const Platetype({super.key, required this.selectedCity});

  @override
  State<Platetype> createState() => _PlatetypeState();
}

class _PlatetypeState extends State<Platetype> {
  String? selectedColor;

  final List<String> plate = [
    "ລັດບໍລິຫານ",
    "ເອກະຊົນລາວ",
    "ບໍລິສັດ/ທຸລະກິດ 100%",
    "ບໍລິສັດ/ທຸລະກິດ 1%",
    "ເອກະຊົນຕ່າງດ້າວ",
    "ອົງການຈັດຕັ້ງສາກົນ(ນຳໃຊ້ສ່ວນຕົວ)",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select a Plate Type")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Choose Your Plate",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: plate.map((plate) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = plate;
                        });

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddVechicle(
                              ownerName: "", 
                              licensePlate: "", 
                              selectedcolor: selectedColor!,
                              selectedCity: widget.selectedCity, // Pass city here
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: selectedColor == plate ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedColor == plate ? Colors.blueAccent : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            plate,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: selectedColor == plate ? Colors.white : Colors.black,
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
