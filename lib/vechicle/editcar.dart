import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class EditCar extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> carData;

  const EditCar({
    Key? key,
    required this.documentId,
    required this.carData,
  }) : super(key: key);

  @override
  State<EditCar> createState() => _EditCarState();
}

class _EditCarState extends State<EditCar> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController brandController;
  late TextEditingController colorController;
  late TextEditingController plateController;
  late TextEditingController nameController;

  // เปลี่ยน province กับ typeplate ให้เป็นตัวแปร String ที่เก็บค่าเลือกใน dropdown
  late String selectedProvince;
  late String selectedTypeplate;

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

  final List<String> plateTypeList = [
    "ລັດບໍລິຫານ",
    "ເອກະຊົນລາວ",
    "ບໍລິສັດ/ທຸລະກິດ 100%",
    "ບໍລິສັດ/ທຸລະກິດ 1%",
    "ເອກະຊົນຕ່າງດ້າວ",
    "ອົງການຈັດຕັ້ງສາກົນ(ນຳໃຊ້ສ່ວນຕົວ)",
  ];

  final Map<String, Map<String, Color>> plateColors = {
    "ລັດບໍລິຫານ": {"background": Colors.blue, "text": Colors.white},
    "ເອກະຊົນລາວ": {"background": Colors.yellow, "text": Colors.black},
    "ບໍລິສັດ/ທຸລະກິດ 100%": {"background": Colors.white, "text": Colors.black},
    "ບໍລິສັດ/ທຸລະກິດ 1%": {"background": Colors.white, "text": Colors.blue},
    "ເອກະຊົນຕ່າງດ້າວ": {"background": Colors.yellow, "text": Colors.lightBlue},
    "ອົງການຈັດຕັ້ງສາກົນ(ນຳໃຊ້ສ່ວນຕົວ)": {
      "background": Colors.white,
      "text": Colors.lightBlue
    },
  };

  @override
  void initState() {
    super.initState();
    brandController = TextEditingController(text: widget.carData["brandName"]);
    colorController = TextEditingController(text: widget.carData["color"]);
    plateController =
        TextEditingController(text: widget.carData["numberplate"]);
    nameController = TextEditingController(text: widget.carData["charplate"]);

    // กำหนดค่าเริ่มต้น dropdown จากข้อมูลเดิม
    selectedProvince = widget.carData["province"] ?? cities[0];
    selectedTypeplate = widget.carData["typeplate"] ?? plateTypeList[0];
  }

  @override
  void dispose() {
    brandController.dispose();
    colorController.dispose();
    plateController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> _updateCarDetails() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.documentId)
          .update({
        "brandName": brandController.text.trim(),
        "color": colorController.text.trim(),
        "numberplate": plateController.text.trim(),
        "province": selectedProvince,
        "typeplate": selectedTypeplate,
        "charplate": nameController.text.trim(),
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Details updated successfully!")),
      );

      Navigator.pop(context, {
        ...widget.carData,
        "brandName": brandController.text.trim(),
        "color": colorController.text.trim(),
        "numberplate": plateController.text.trim(),
        "province": selectedProvince,
        "typeplate": selectedTypeplate,
        "charplate": nameController.text.trim(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update details")),
      );
      debugPrint("Error updating car: $e");
    }
  }

  InputDecoration _buildDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blueAccent.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Car Details"),
        backgroundColor: Colors.blueAccent,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Brand field
                Material(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: TextFormField(
                    controller: brandController,
                    decoration:
                        _buildDecoration("Brand Name", Icons.directions_car),
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? "Enter brand" : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Color field
                Material(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: TextFormField(
                    controller: colorController,
                    decoration: _buildDecoration("Color", Icons.color_lens),
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? "Enter color" : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Plate field
                Material(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: TextFormField(
                    controller: plateController,
                    decoration: _buildDecoration(
                        "License Plate", Icons.format_list_numbered_sharp),
                    textInputAction: TextInputAction.next,
                    keyboardType:
                        TextInputType.number, // 👈 only numeric keyboard
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // 👈 allow digits only
                    ],
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Enter plate number"
                        : null,
                  ),
                ),

                const SizedBox(height: 16),

                // Province Dropdown
                Material(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: DropdownButtonFormField<String>(
                    value: selectedProvince,
                    decoration:
                        _buildDecoration("Province", Icons.location_city),
                    items: cities
                        .map((city) => DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedProvince = val;
                        });
                      }
                    },
                    validator: (val) =>
                        val == null || val.isEmpty ? "Select province" : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Plate Type Dropdown
                Material(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: double.infinity, // or a fixed width
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedTypeplate,
                      decoration: _buildDecoration("Plate Type", Icons.style),
                      items: plateTypeList
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedTypeplate = val;
                          });
                        }
                      },
                      validator: (val) => val == null || val.isEmpty
                          ? "Select plate type"
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Charplate field
                Material(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: TextFormField(
                    controller: nameController,
                    decoration:
                        _buildDecoration("Character Plate", Icons.text_fields),
                    textInputAction: TextInputAction.done,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Enter plate character"
                        : null,
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton.icon(
                  onPressed: _updateCarDetails,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Changes"),
                  style: ElevatedButton.styleFrom(
                    elevation: 6,
                    shadowColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
