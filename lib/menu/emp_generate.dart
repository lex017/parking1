import 'dart:typed_data';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:parking1/menu/emp_qrpay.dart';
import 'package:parking1/menu/real_ticket.dart';
import 'dart:convert';

class EmpGenerate extends StatefulWidget {
  final String empId; // Employee ID
  final String locationId; // Location ID

  const EmpGenerate({
    super.key,
    required this.empId,
    required this.locationId,
  });

  @override
  State<EmpGenerate> createState() => _EmpGenerateState();
}

class _EmpGenerateState extends State<EmpGenerate> {
  // For toggling between cash and QR payment
  bool _isCashPayment = true;

  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _selectedProvince;
  String? _selectedPlateType;
  late String empId;
  late String locationId;
  String? imageUrl; // Variable to store QR image URL
  String? qrimage; // Variable to store QR image URL
  bool isLoading = true; // Check image loading status
  int price = 0;

  final TextEditingController nameplateController = TextEditingController();
  final TextEditingController plateController = TextEditingController();

  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";

  final List<String> _provinces = [
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

  final Map<String, Map<String, Color>> _plateColors = {
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
    empId = widget.empId;
    locationId = widget.locationId;
    fetchParkingData();
  }

  Future<void> fetchParkingData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('parking')
          .doc(locationId)
          .get();

      if (doc.exists) {
        setState(() {
          price = doc['price'];
          qrimage = doc['qrImage']; // Assuming qr image is stored in 'qrUrl'
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching parking data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String?> _uploadImageToCloudinary() async {
    try {
      if (_selectedImage == null && _imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select an image')));
        return null;
      }
      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset;

      if (_imageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', _imageBytes!));
      } else if (_selectedImage != null) {
        request.files.add(
            await http.MultipartFile.fromPath('file', _selectedImage!.path));
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final data = jsonDecode(responseData.body);
        return data['secure_url'];
      } else {
        print("Cloudinary Upload Failed: ${response.reasonPhrase}");
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')));
        return null;
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error uploading image')));
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Select Image Source"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: const Text("Take Photo"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: const Text("Choose from Gallery"),
              ),
            ],
          );
        },
      );

      if (source != null) {
        final XFile? pickedFile = await _picker.pickImage(source: source);
        if (pickedFile != null) {
          if (kIsWeb) {
            final Uint8List bytes = await pickedFile.readAsBytes();
            setState(() {
              _imageBytes = bytes;
              _selectedImage = null;
            });
          } else {
            setState(() {
              _selectedImage = File(pickedFile.path);
              _imageBytes = null;
            });
          }
        }
      }
    } catch (e) {
      print("Error selecting image: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error selecting image')));
    }
  }

  Future<void> _saveTicketToFirebase(String paymentMethod) async {
    if (_selectedProvince == null ||
        _selectedPlateType == null ||
        nameplateController.text.isEmpty ||
        plateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? imageUrl;
    if (_selectedImage != null || _imageBytes != null) {
      imageUrl = await _uploadImageToCloudinary();
      if (imageUrl == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    String ticketId = "ticket${DateTime.now().millisecondsSinceEpoch}";

    Map<String, dynamic> ticketData = {
      "province": _selectedProvince,
      "typeplate": _selectedPlateType,
      "charplate": nameplateController.text,
      "numberplate": plateController.text,
      "empId": empId,
      "locationId": locationId,
      "imageUrl": imageUrl ?? "",
      "Status": "check-in",
      "ticketId": ticketId,
      "timestamp": FieldValue.serverTimestamp(),
      "paymentMethod": paymentMethod,
    };

    try {
      await FirebaseFirestore.instance
          .collection("ticketreal")
          .doc(ticketId)
          .set(ticketData);

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => RealTicket(ticketData: ticketData)),
        );
      }
    } catch (e) {
      print("Error saving ticket: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate ticket')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildCashPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedProvince,
            items: _provinces.map((String province) {
              return DropdownMenuItem<String>(
                  value: province, child: Text(province));
            }).toList(),
            decoration: const InputDecoration(
              labelText: "Province",
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _selectedProvince = value;
              });
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedPlateType,
            items: _plateColors.keys.map((String plateType) {
              return DropdownMenuItem<String>(
                value: plateType,
                child: Text(
                  plateType,
                  style: TextStyle(
                    color: _plateColors[plateType]!['text'],
                    backgroundColor: _plateColors[plateType]!['background'],
                  ),
                ),
              );
            }).toList(),
            decoration: const InputDecoration(
              labelText: "Plate Type",
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _selectedPlateType = value;
              });
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: nameplateController,
            inputFormatters: [UpperCaseTextFormatter()],
            decoration: const InputDecoration(
              labelText: "Name Plate",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: plateController,
            keyboardType: TextInputType.number, // Show number keyboard
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Allow digits only
            ],
            decoration: const InputDecoration(
              labelText: "Plate Number",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                      : const Center(
                          child: Text("Tap to upload",
                              style: TextStyle(color: Colors.grey))),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _isLoading ? null : () => _saveTicketToFirebase("cash"),
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.receipt_long),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                child: Text(
                  _isLoading
                      ? "Processing..."
                      : "Generate Ticket (Cash Payment)",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRPaymentPage() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (price == null) {
      return const Center(child: Text("Unable to load parking data."));
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : qrimage == null
                    ? const Center(
                        child: Text(
                          "Failed to load image",
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                      )
                    : Center(
                        child: Image.network(
                          qrimage!,
                          fit: BoxFit.cover,
                        ),
                      ),
            const SizedBox(height: 20),
            Text(
              "QR Payment",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Text(
              "Amount to Pay:",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              "$price LAK",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isCashPayment = false;
                });
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EmpQrpay(
                      empId: empId,
                      locationId: locationId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward,
                  color: Colors.amber, size: 20),
              label: const Text(
                "Continue to Payment",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                elevation: 6,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Ticket'),
      ),
      body: Column(
        children: [
          // Toggle buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ToggleButtons(
              isSelected: [_isCashPayment, !_isCashPayment],
              onPressed: (index) {
                setState(() {
                  _isCashPayment = index == 0;
                });
              },
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              fillColor: Colors.blue,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Cash Payment"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("QR Payment"),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: _isCashPayment
                  ? _buildCashPaymentForm()
                  : _buildQRPaymentPage(),
            ),
          ),
        ],
      ),
    );
  }
}

// Utility formatter to make input uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
