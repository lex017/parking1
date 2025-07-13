import 'dart:io';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parking1/data_save/parking_pagekage.dart';
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

 Future<void> _pickAndCropImage(bool isQR) async {
  final picked = await _picker.pickImage(source: ImageSource.gallery);
  if (picked == null) return;

  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    compressQuality: 100,
    aspectRatio: isQR
        ? const CropAspectRatio(ratioX: 243, ratioY: 260) // ≈ 486:520
        : const CropAspectRatio(ratioX: 16, ratioY: 9),
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop Image',
        toolbarColor: Colors.blueAccent,
        toolbarWidgetColor: Colors.white,
        initAspectRatio: isQR
            ? CropAspectRatioPreset.original
            : CropAspectRatioPreset.ratio16x9,
        lockAspectRatio: true, // 🔒 ล็อกสัดส่วนตามที่กำหนด
      ),
    ],
  );

  if (cropped == null) return;

  final file = File(cropped.path);
  final bytes = await file.readAsBytes();

  setState(() {
    if (isQR) {
      _qrImage = file;
      _qrImageBytes = bytes;
    } else {
      _parkingImage = file;
      _parkingImageBytes = bytes;
    }
  });
}


  Widget _buildPicker({
    required int count,
    required int selected,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      itemExtent: 40,
      perspective: 0.002,
      diameterRatio: 1.5,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      controller: FixedExtentScrollController(initialItem: selected),
      childDelegate: ListWheelChildBuilderDelegate(
        builder: (context, index) {
          return Center(
            child: Text(
              index.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          );
        },
        childCount: count,
      ),
    );
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      );

  void _pickCustomTime(TextEditingController controller) {
    int selectedHour = DateTime.now().hour;
    int selectedMinute = DateTime.now().minute;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 360,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Icon(Icons.access_time_rounded,
                        color: Colors.blueAccent, size: 40),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Select Time',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildPicker(
                            count: 24,
                            selected: selectedHour,
                            onChanged: (value) {
                              setModalState(() => selectedHour = value);
                            },
                          ),
                        ),
                        Expanded(
                          child: _buildPicker(
                            count: 60,
                            selected: selectedMinute,
                            onChanged: (value) {
                              setModalState(() => selectedMinute = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        'Confirm Time',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final formatted =
                            '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
                        controller.text = formatted;
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
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
        onTap: () => _pickAndCropImage(isQR),
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
                      child: Text(label,
                          style: const TextStyle(color: Colors.grey)),
                    ),
        ),
      );

  void _onNext() {
    if (!_formKey.currentState!.validate() ||
        (_parkingImage == null && _parkingImageBytes == null) ||
        (_qrImage == null && _qrImageBytes == null) ||
        _selectedEVOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete all fields')));
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
          parkingImageBytes:
              _parkingImageBytes ?? File(_parkingImage!.path).readAsBytesSync(),
          qrImageBytes: _qrImageBytes ?? File(_qrImage!.path).readAsBytesSync(),
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
            _buildSectionCard(
              child: Column(children: [
                _buildTextField(_nameController, 'Parking Name'),
                const SizedBox(height: 12),
                _buildTextField(_addressController, 'Address'),
                const SizedBox(height: 12),
                _buildTextField(_descriptionController, 'Description'),
                const SizedBox(height: 12),
                _buildTextField(_landmarkController, 'Landmark'),
              ]),
            ),
            _buildSectionCard(
              child: Row(children: [
                Expanded(
                  child: _buildTimeField(
                      _openTimeController, 'Open', Colors.blueAccent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeField(
                      _closeTimeController, 'Close', Colors.redAccent),
                ),
              ]),
            ),
            _buildSectionCard(
              child: Column(children: [
                _buildTextField(_priceController, 'Price',
                    type: TextInputType.number),
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
              ]),
            ),
            _buildSectionCard(
              child: Column(children: [
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
              ]),
            ),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.arrow_forward, color: Colors.white),
        label: const Text(
          'Next',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        onPressed: _onNext,
      ),
    );
  }
}
