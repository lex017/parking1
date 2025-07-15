import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parking1/detailownner/mapedit.dart';
import 'package:time_picker_spinner/time_picker_spinner.dart';

class EditMap extends StatefulWidget {
  final String documentId;
  const EditMap({required this.documentId, Key? key}) : super(key: key);

  @override
  State<EditMap> createState() => _EditMapState();
}

class _EditMapState extends State<EditMap> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _carSlotCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _timeopenCtrl = TextEditingController();
  final _timecloseCtrl = TextEditingController();

  // Dropdown state
  String? _selectedTag;
  final _tagOptions = ['EV', 'none'];
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _loading = true;
  DateTime now = DateTime.now();
  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

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

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

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

  Future<String?> _uploadImageToCloudinary() async {
    try {
      if (_selectedImage == null && _imageBytes == null) {
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
        return null;
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      return null;
    }
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection('parking')
        .doc(widget.documentId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _nameCtrl.text = data['nameparking'] ?? '';
      _addressCtrl.text = data['address'] ?? '';
      _priceCtrl.text = (data['price'] ?? '').toString();
      _carSlotCtrl.text = (data['car_slot'] ?? '').toString();
      _imageUrlCtrl.text = data['imageUrl'] ?? '';
      _descriptionCtrl.text = data['description'] ?? '';
      _timeopenCtrl.text = data['openTime'] ?? '';
      _timecloseCtrl.text = data['closeTime'] ?? '';
      _selectedTag = data['tag'] ?? _tagOptions.first;
    }

    setState(() => _loading = false);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // Upload image if a new one is selected
      String? imageUrl = _imageUrlCtrl.text;
      if (_selectedImage != null || _imageBytes != null) {
        final uploadedUrl = await _uploadImageToCloudinary();
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      await FirebaseFirestore.instance
          .collection('parking')
          .doc(widget.documentId)
          .update({
        'nameparking': _nameCtrl.text,
        'address': _addressCtrl.text,
        'price': int.tryParse(_priceCtrl.text) ?? 0,
        'car_slot': int.tryParse(_carSlotCtrl.text) ?? 0,
        'imageUrl': imageUrl,
        'description': _descriptionCtrl.text,
        'openTime': _timeopenCtrl.text,
        'closeTime': _timecloseCtrl.text,
        'tag': _selectedTag,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _carSlotCtrl.dispose();
    _imageUrlCtrl.dispose();
    _descriptionCtrl.dispose();
    _timeopenCtrl.dispose();
    _timecloseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Parking'),
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          children: [
            // Name & Address Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              margin: EdgeInsets.only(
                  top: screenHeight * 0.02, bottom: screenHeight * 0.02),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02,
                  horizontal: screenWidth * 0.03,
                ),
                child: GestureDetector(
                  onTap: () async {
                    final selectedLocation = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MapPickerPage()),
                    );
                    if (selectedLocation != null) {
                      setState(() {
                        _addressCtrl.text = selectedLocation['address'];
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: _buildTextField(
                      _addressCtrl,
                      'Address (Tap to select)',
                      Icons.location_on,
                    ),
                  ),
                ),
              ),
            ),

            // Price Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              margin: EdgeInsets.only(bottom: screenHeight * 0.02),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02,
                  horizontal: screenWidth * 0.03,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _priceCtrl,
                        'Price',
                        Icons.attach_money,
                        keyboard: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Time Open & Close
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              margin: EdgeInsets.only(bottom: screenHeight * 0.02),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02,
                  horizontal: screenWidth * 0.03,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _timeopenCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Open Time',
                          prefixIcon: Icon(Icons.access_time),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onTap: () => _pickCustomTime(_timeopenCtrl),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter Open Time' : null,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: TextFormField(
                        controller: _timecloseCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Close Time',
                          prefixIcon: Icon(Icons.access_time_filled),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onTap: () => _pickCustomTime(_timecloseCtrl),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter Close Time'
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Image Preview
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              shadowColor: Colors.black26,
              margin: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.015, horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                    child: (_imageBytes != null || _selectedImage != null)
                        ? (kIsWeb
                            ? Image.memory(
                                _imageBytes!,
                                height: screenHeight * 0.25,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                _selectedImage!,
                                height: screenHeight * 0.25,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ))
                        : (_imageUrlCtrl.text.isNotEmpty
                            ? Image.network(
                                _imageUrlCtrl.text,
                                height: screenHeight * 0.25,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: screenHeight * 0.25,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey[200]!,
                                      Colors.grey[100]!
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "No image selected",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              )),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenHeight * 0.015,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.photo_library_outlined,
                          color: Colors.white, size: 22),
                      label: Text(
                        "Choose Image",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.018),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                        shadowColor: Colors.deepPurple.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tag & Description
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              margin: EdgeInsets.only(bottom: screenHeight * 0.03),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02,
                  horizontal: screenWidth * 0.03,
                ),
                child: Column(
                  children: [
                   DropdownButtonFormField<String>(
  value: _tagOptions.contains(_selectedTag) ? _selectedTag : null,
  items: _tagOptions.map((tag) {
    return DropdownMenuItem<String>(
      value: tag,
      child: Text(tag),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      _selectedTag = value;
    });
  },
  validator: (value) =>
      value == null ? 'Please select a tag' : null,
  decoration: InputDecoration(
    labelText: 'Tag',
    prefixIcon: Icon(Icons.label),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
),

                    SizedBox(height: screenHeight * 0.02),
                    TextFormField(
                      controller: _descriptionCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter a description';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Save Button
            SizedBox(height: screenHeight * 0.025),
            ElevatedButton(
              onPressed: () async {
                final uploadedUrl = await _uploadImageToCloudinary();
                if (uploadedUrl != null) {
                  _imageUrlCtrl.text = uploadedUrl;
                }
                _saveChanges();
              },
              child: Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
                shadowColor: Colors.deepPurple.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
