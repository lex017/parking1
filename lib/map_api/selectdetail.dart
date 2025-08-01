import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:parking1/cash/QrPay.dart';
import 'package:parking1/data_save/licenseplate.dart';

class detailPay extends StatefulWidget {
  final String documentId;

  const detailPay({required this.documentId, super.key});

  @override
  State<detailPay> createState() => _BtnLocationState();
}

class _BtnLocationState extends State<detailPay> {
  int pricePerHour = 0;
  String? selectedCar; // Store the selected car
  String? selectedVehicleId;

  List<Map<String, String>> carList = []; // Ensure carList is initialized
  String selectedCharplate = '';
  String selectedNumberplate = '';
  String selectedColor = '';
  String selectedProvince = '';
  String selectedTypeplate = '';
  @override
  void initState() {
    super.initState();
    _fetchCarList();
  }

  void _showImagePopup(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text(
                "Failed to load image",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Fetch user's registered vehicles from Firestore
  Future<void> _fetchCarList() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return; // No user logged in
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('userId', isEqualTo: currentUserId) // Only get user's cars
        .get();

    setState(() {
      carList = snapshot.docs.map((doc) {
        return {
          'vehicleId': doc.id, // Store vehicleId
          'brandName': doc['brandName'] as String,
          'charplate': doc['charplate'] as String,
          'numberplate': doc['numberplate'] as String,
          'color': doc['color'] as String,
          'province': doc['province'] as String,
          'typeplate': doc['typeplate'] as String,
        };
      }).toList();
    });
  }

  // Function to select a car
  Future<void> _selectCar() async {
    Map<String, String>? selected = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select_a_Car".tr()),
          content: SizedBox(
            width: double.maxFinite,
            child: carList.isEmpty
                ? Center(child: Text("No_vehicles_found".tr()))
                : ListView.builder(
                    itemCount: carList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(carList[index]['brandName']!),
                        onTap: () {
                          Navigator.pop(context, carList[index]);
                        },
                      );
                    },
                  ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        selectedCar = selected['brandName']!;
        selectedVehicleId = selected['vehicleId']!;
        selectedCharplate = selected['charplate']!;
        selectedNumberplate = selected['numberplate']!;
        selectedColor = selected['color']!;
        selectedProvince = selected['province']!;
        selectedTypeplate = selected['typeplate']!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              // StreamBuilder to fetch image
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('parking')
                    .doc(widget.documentId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return const SizedBox(
                      height: 300,
                      child: Center(
                        child: Text(
                          "Error loading image",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const SizedBox(
                      height: 300,
                      child: Center(
                        child: Text(
                          "No image available",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final imageUrl = data['imageUrl'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      if (imageUrl.isNotEmpty) {
                        _showImagePopup(imageUrl);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 300, // Full height for the image
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                        image: imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: Colors.grey.shade200,
                      ),
                      child: imageUrl.isEmpty
                          ? const Center(
                              child: Text(
                                "No image available",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
              // Back Button
              Positioned(
                top: 40,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),

          // Information section
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('parking')
                  .doc(widget.documentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Error loading data",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text(
                      "No data available",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final nameLocation = data['nameparking'] ?? 'Unknown Name';
                final price = data['price'] ?? 0;
                pricePerHour = price;
                final formatter =
                    NumberFormat('#,##0', context.locale.languageCode);
                String formattedPrice = formatter.format(pricePerHour);

                return Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Location with Buttons on the Right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              nameLocation,
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Text(
                      //   'itemPrice'.tr(args: [
                      //     formattedPrice
                      //   ]), // Pass the already formatted price
                      //   style: const TextStyle(
                      //     fontSize: 18,
                      //     fontWeight: FontWeight.bold,
                      //     color: Colors.black,
                      //   ),
                      // ),

                      const SizedBox(height: 20),

                      // Button to pick time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "SelectCar".tr(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                        color: Colors.blueAccent, width: 1.0),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton2<String>(
                                      isExpanded: true,
                                      hint: Text(
                                        'ChooseaCar'.tr(),
                                        style: TextStyle(color: Colors.black54),
                                      ),
                                      items: [
                                        ...carList.map((car) {
                                          return DropdownMenuItem<String>(
                                            value: car['brandName'],
                                            child: Text(
                                                car['brandName'] ?? 'Unknown'),
                                          );
                                        }).toList(),
                                        DropdownMenuItem<String>(
                                          value: 'add_new',
                                          child: Row(
                                            children: [
                                              Icon(Icons.add,
                                                  color: Colors.blueAccent),
                                              SizedBox(width: 8),
                                              Text(
                                                'AddNewCar'.tr(),
                                                style: TextStyle(
                                                  color: Colors.blueAccent,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      value: selectedCar,
                                      onChanged: (value) {
                                        if (value == 'add_new') {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    LicensePlate()),
                                          );
                                        } else {
                                          setState(() {
                                            selectedCar = value;

                                            final selected = carList.firstWhere(
                                              (car) =>
                                                  car['brandName'] == value,
                                              orElse: () => {},
                                            );

                                            selectedVehicleId =
                                                selected['vehicleId'] ?? '';
                                            selectedCharplate =
                                                selected['charplate'] ?? '';
                                            selectedNumberplate =
                                                selected['numberplate'] ?? '';
                                            selectedColor =
                                                selected['color'] ?? '';
                                            selectedProvince =
                                                selected['province'] ?? '';
                                            selectedTypeplate =
                                                selected['typeplate'] ?? '';
                                          });
                                        }
                                      },
                                      dropdownStyleData: DropdownStyleData(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.white,
                                          border: Border.all(
                                              color: Colors.blueAccent),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Total Price and Navigate Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total_Price".tr(),
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              Text(
                                'itemPrice'.tr(args: [
                                  formattedPrice
                                ]), // Pass the already formatted price
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: selectedCar == null
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (c) => QrPay(
                                          documentId: widget.documentId,
                                          selectedCar:
                                              selectedCar!, // Pass selected car
                                          selectedVehicleId: selectedVehicleId!,
                                          selectedCharplate: selectedCharplate,
                                          selectedNumberplate:
                                              selectedNumberplate,
                                          selectedColor: selectedColor,
                                          selectedProvince: selectedProvince,
                                          selectedTypeplate: selectedTypeplate,
                                          pricePerHour: pricePerHour,
                                        ),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.arrow_forward,
                                color: Colors.white),
                            label: Text(
                              "GO".tr(),
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              backgroundColor: selectedCar == null
                                  ? Colors.grey
                                  : Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
