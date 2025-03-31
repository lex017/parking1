import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parking1/cash/QrPay.dart';

class detailPay extends StatefulWidget {
  final String documentId;

  const detailPay({required this.documentId, super.key});

  @override
  State<detailPay> createState() => _BtnLocationState();
}

class _BtnLocationState extends State<detailPay> {
  int pricePerHour = 0;
  TimeOfDay? selectedTime; // To store the selected time
  String? selectedCar; // Store the selected car
  List<String> carList = [];

  @override
  void initState() {
    super.initState();
    _fetchCarList(); 
  }

  // Function to show the time picker
  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
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
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('vehicles').get();

    setState(() {
      carList = snapshot.docs.map((doc) => doc['brandName'] as String).toList();
    });
  }

  // Function to select a car
  Future<void> _selectCar() async {
    String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select a Car"),
          content: SizedBox(
            width: double.maxFinite,
            child: carList.isEmpty
                ? const Center(child: Text("No vehicles found"))
                : ListView.builder(
                    itemCount: carList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(carList[index]),
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
        selectedCar = selected;
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
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Text(
                        "Price: $pricePerHour LAK",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Button to pick time
                      Row(
                        children: [
                          const Text(
                            "Select Time: ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: _pickTime,
                            child: Text(
                              selectedTime != null
                                  ? "${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')} ${selectedTime!.period == DayPeriod.am ? 'AM' : 'PM'}"
                                  : "Pick Time",
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Text(
                                  "Select Car: ",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 10),
                                DropdownButton<String>(
                                  value: selectedCar, // Currently selected car
                                  hint: const Text("Choose a Car"),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedCar = newValue;
                                    });
                                  },
                                  items: carList.map<DropdownMenuItem<String>>(
                                      (String car) {
                                    return DropdownMenuItem<String>(
                                      value: car,
                                      child: Text(car),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
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
                              const Text(
                                "Total Price",
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              Text(
                                "$pricePerHour LAK",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: selectedCar == null || selectedTime == null
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (c) => QrPay(
                                          documentId: widget.documentId,
                                          selectedCar: selectedCar!, // Pass selected car
                                          selectedTime: selectedTime!, // Optionally pass the time
                                        ),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.arrow_forward,
                                color: Colors.white),
                            label: const Text(
                              "GO",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              backgroundColor: selectedCar == null || selectedTime == null
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
