import 'dart:io';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parking1/data_save/parking_pagekage.dart';
import 'package:time_picker_spinner/time_picker_spinner.dart';
import 'package:intl/intl.dart';

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
  final _picker = ImagePicker();
  final _openTimeController = TextEditingController();
  final _closeTimeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedEVOption;
  final _evOptions = ['EV', 'None'];

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.address;
  }

  Future<void> _pickImage(bool isQR) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = kIsWeb ? await picked.readAsBytes() : null;
    setState(() {
      if (isQR) {
        _qrImageBytes = bytes;
        _qrImage = bytes == null ? File(picked.path) : null;
      } else {
        _parkingImageBytes = bytes;
        _parkingImage = bytes == null ? File(picked.path) : null;
      }
    });
  }

  Widget _buildSectionCard({required Widget child}) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      );

  Widget _buildTextField(
    TextEditingController c,
    String label, {
    TextInputType type = TextInputType.text,
    bool required = true,
  }) =>
      TextFormField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(labelText: label),
        validator: required ? (v) => v!.isEmpty ? 'Required' : null : null,
      );

  Widget _buildTimeField(TextEditingController c, String label, Color color) =>
      TextFormField(
        controller: c,
        readOnly: true,
        onTap: () => _pickCustomTime(c),
        decoration: InputDecoration(
          labelText: '$label Time',
          prefixIcon: Icon(Icons.access_time, color: color),
          suffixIcon: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => _pickCustomTime(c),
          ),
          filled: true,
          fillColor: color.withOpacity(0.1),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      );

 void _pickCustomTime(TextEditingController controller) {
  DateTime selected = DateTime.now(); // Define it here so it retains value

  showModalBottomSheet(
    context: context,
    builder: (_) {
      return SizedBox(
        height: 320,
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            children: [
              Expanded(
                child: TimePickerSpinner(
                  is24HourMode: true,
                  isShowSeconds: false,
                  normalTextStyle:
                      const TextStyle(fontSize: 18, color: Colors.grey),
                  highlightedTextStyle:
                      const TextStyle(fontSize: 24, color: Colors.black),
                  spacing: 40,
                  itemHeight: 60,
                  isForce2Digits: true,
                  time: selected,
                  onTimeChange: (time) {
                    selected = time; // ✅ Save the new time
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  controller.text = DateFormat('HH:mm').format(selected); // ✅ Will now reflect selected time
                  Navigator.pop(context);
                },
                child: const Text('Confirm'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildImagePicker({
    required bool isQR,
    required String label,
    required File? imageFile,
    required Uint8List? imageBytes,
  }) =>
      GestureDetector(
        onTap: () => _pickImage(isQR),
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: imageFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(imageFile, fit: BoxFit.cover),
                )
              : imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(imageBytes, fit: BoxFit.cover),
                    )
                  : Center(
                      child: Text(label, style: const TextStyle(color: Colors.grey)),
                    ),
        ),
      );

  void _onNext() {
    if (!_formKey.currentState!.validate() ||
        (_parkingImage == null && _parkingImageBytes == null) ||
        (_qrImage == null && _qrImageBytes == null) ||
        _selectedEVOption == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please complete all fields')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParkingPagekage(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          description: _descriptionController.text.trim(),
          price: int.parse(_priceController.text.trim()),
          evSupport: _selectedEVOption!,
          latitude: widget.latitude,
          longitude: widget.longitude,
          parkingImageBytes: _parkingImageBytes ??
              File(_parkingImage!.path).readAsBytesSync(),
          qrImageBytes:
              _qrImageBytes ?? File(_qrImage!.path).readAsBytesSync(),
          parkingImage: _parkingImage!,
          qrImage: _qrImage!,
          landmark: _landmarkController.text.trim(),
          openTime: _openTimeController.text.trim(),
          closeTime: _closeTimeController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Parking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            _buildSectionCard(child: Column(children: [
              _buildTextField(_nameController, 'Parking Name'),
              const SizedBox(height: 12),
              _buildTextField(_addressController, 'Address'),
              const SizedBox(height: 12),
              _buildTextField(_descriptionController, 'Description'),
              const SizedBox(height: 12),
              _buildTextField(_landmarkController, 'Landmark'),
            ])),
            _buildSectionCard(child: Column(children: [
              Row(children: [
                Expanded(
                    child: _buildTimeField(
                        _openTimeController, 'Open', Colors.blueAccent)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildTimeField(
                        _closeTimeController, 'Close', Colors.redAccent)),
              ]),
            ])),
            _buildSectionCard(child: Column(children: [
              _buildTextField(
                  _priceController, 'Price', type: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedEVOption,
                items: _evOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                decoration: const InputDecoration(labelText: 'EV Support'),
                onChanged: (v) => setState(() => _selectedEVOption = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ])),
            _buildSectionCard(child: Column(children: [
              _buildImagePicker(
                  isQR: false,
                  label: 'Select Parking Image',
                  imageFile: _parkingImage,
                  imageBytes: _parkingImageBytes),
              const SizedBox(height: 12),
              _buildImagePicker(
                  isQR: true,
                  label: 'Select QR Code',
                  imageFile: _qrImage,
                  imageBytes: _qrImageBytes),
            ])),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Next'),
        onPressed: _onNext,
      ),
    );
  }
}
