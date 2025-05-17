// btn_add_parking.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parking1/data_save/parking_pagekage.dart';

class BtnaddParking extends StatefulWidget {
  final String address;
  final double latitude;
  final double longitude;

  const BtnaddParking({
    Key? key,
    required this.address,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<BtnaddParking> createState() => _BtnaddParkingState();
}

class _BtnaddParkingState extends State<BtnaddParking> {
  File? _parkingImage;
  Uint8List? _parkingImageBytes;
  File? _qrImage;
  Uint8List? _qrImageBytes;
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedEVOption;
  final List<String> _evOptions = ["EV", "None"];

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.address;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        if (kIsWeb) {
          final Uint8List bytes = await pickedFile.readAsBytes();
          setState(() {
            _parkingImageBytes = bytes;
            _parkingImage = null;
          });
        } else {
          setState(() {
            _parkingImage = File(pickedFile.path);
            _parkingImageBytes = null;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
      }
    } catch (e) {
      print("Error selecting image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error selecting image')),
      );
    }
  }

  Future<void> _pickImageQR() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        if (kIsWeb) {
          final Uint8List bytes = await pickedFile.readAsBytes();
          setState(() {
            _qrImageBytes = bytes;
            _qrImage = null;
          });
        } else {
          setState(() {
            _qrImage = File(pickedFile.path);
            _qrImageBytes = null;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
      }
    } catch (e) {
      print("Error selecting image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error selecting image')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Parking")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Parking Name"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Address"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedEVOption,
                items: _evOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedEVOption = value),
                decoration: const InputDecoration(labelText: "EV Support"),
                validator: (value) => value == null ? "Select one" : null,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _parkingImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_parkingImage!, fit: BoxFit.cover),
                        )
                      : _parkingImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(_parkingImageBytes!,
                                  fit: BoxFit.cover),
                            )
                          : const Center(
                              child: Icon(Icons.add_a_photo,
                                  size: 50, color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImageQR,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _qrImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_qrImage!, fit: BoxFit.cover),
                        )
                      : _qrImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(_qrImageBytes!,
                                  fit: BoxFit.cover),
                            )
                          : const Center(
                              child: Icon(Icons.add_a_photo,
                                  size: 50, color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() &&
                      (_parkingImage != null || _parkingImageBytes != null) &&
                      (_qrImage != null || _qrImageBytes != null)) {
                    final parkingBytes = _parkingImageBytes ??
                        await _parkingImage!.readAsBytes();
                    final qrBytes =
                        _qrImageBytes ?? await _qrImage!.readAsBytes();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ParkingPagekage(
                          name: _nameController.text.trim(),
                          address: _addressController.text.trim(),
                          description: _descriptionController.text.trim(),
                          price: int.parse(_priceController.text.trim()),
                          evSupport: _selectedEVOption!,
                          latitude: widget.latitude,
                          longitude: widget.longitude,
                          parkingImageBytes: parkingBytes,
                          qrImageBytes: qrBytes,
                          parkingImage: _parkingImage!,
                          qrImage: _qrImage!,
                        ),
                      ),
                    );
                  }
                },
                child: const Text("Next"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
