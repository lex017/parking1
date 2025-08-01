import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // Ensure this is imported for FilteringTextInputFormatter

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
        SnackBar(content: Text("Details_updated_successfully".tr())), // Localized
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
        SnackBar(content: Text("Failed_to_update_details".tr())), // Localized
      );
      debugPrint("Error updating car: $e");
    }
  }

  Future<void> _deleteCar() async {
    // Show a confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Confirm_Delete".tr()), // Localized
          content: Text("Are_you_sure_you_want_to_delete_this_car".tr()), // Localized
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false), // Dismiss and return false
              child: Text("Cancel".tr()), // Localized
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true), // Dismiss and return true
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Delete".tr(), style: const TextStyle(color: Colors.white)), // Localized
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.documentId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Car_deleted_successfully".tr())), // Localized
        );

        // Pop twice: once to close EditCar screen, once to refresh previous list (assuming it navigates back to a list)
        Navigator.pop(context); // Pop current screen
        // Depending on your navigation flow, you might need to pop again
        // Navigator.pop(context); // Example: If you need to go back past the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed_to_delete_car".tr())), // Localized
        );
        debugPrint("Error deleting car: $e");
      }
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
        title: Text("Edit_Car_Details".tr()),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            onPressed: _deleteCar,
            tooltip: "Delete_Car".tr(), // Localized
          ),
        ],
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
                        _buildDecoration("Brand_Name".tr(), Icons.directions_car), // Localized
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? "Enter_brand".tr() : null, // Localized
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
                    decoration: _buildDecoration("Color".tr(), Icons.color_lens), // Localized
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? "Enter_color".tr() : null, // Localized
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
                        "City_Plate".tr(), Icons.format_list_numbered_sharp),
                    textInputAction: TextInputAction.next,
                    keyboardType:
                        TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly,
                    ],
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Enter_plate_number".tr()
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
                        _buildDecoration("Province".tr(), Icons.location_city),
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
                        val == null || val.isEmpty ? "Select_province".tr() : null,
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
                      decoration: _buildDecoration("Plate_Type".tr(), Icons.style),
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
                          ? "Select_plate_type".tr()
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
                        _buildDecoration("Name_Plate".tr(), Icons.text_fields),
                    textInputAction: TextInputAction.done,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Enter_plate_character".tr()
                        : null,
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton.icon(
                  onPressed: _updateCarDetails,
                  icon: const Icon(Icons.save),
                  label: Text("Save_Changes".tr()),
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