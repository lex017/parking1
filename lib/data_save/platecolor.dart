import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:parking1/data_save/addvechicle.dart'; // Assuming this is your AddVehicle page

class Platetype extends StatefulWidget {
  final String selectedCity;
  const Platetype({super.key, required this.selectedCity});

  @override
  State<Platetype> createState() => _PlatetypeState();
}

class _PlatetypeState extends State<Platetype> {
  String? selectedPlate;

  final Map<String, Map<String, Color>> plateColors = {
    "ລັດບໍລິຫານ": {"background": Colors.blue, "text": Colors.white},
    "ເອກະຊົນລາວ": {"background": Colors.yellow, "text": Colors.black},
    "ບໍລິສັດ/ທຸລະກິດ 100%": {"background": Colors.white, "text": Colors.black},
    "ບໍລິສັດ/ທຸລະກິດ 1%": {"background": Colors.white, "text": Colors.blue},
    "ເອກະຊົນຕ່າງດ້າວ": {"background": Colors.yellow, "text": Colors.lightBlue},
    "ອົງການຈັດຕັ້ງສາກົນ(ນຳໃຊ້ສ່ວນຕົວ)": {"background": Colors.white, "text": Colors.lightBlue},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select_Plate".tr())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: plateColors.keys.map((plate) {
                    final bool isSelected = selectedPlate == plate;
                    final Color plateColor =
                        plateColors[plate]?["background"] ?? Colors.grey;
                    final Color textColor =
                        plateColors[plate]?["text"] ?? Colors.black;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedPlate = plate;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: plateColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: [
                            if (isSelected)
                              const BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.selectedCity,
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
              
                            Text(
                              plate,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedPlate != null
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddVechicle(
                            ownerName: "",
                            licensePlate: "",
                            selectedcolor: selectedPlate!,
                            selectedCity: widget.selectedCity,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text("Next".tr()),
            ),
          ],
        ),
      ),
    );
  }
}