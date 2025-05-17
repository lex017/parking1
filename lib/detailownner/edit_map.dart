import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditMap extends StatefulWidget {
  final String documentId;
  const EditMap({required this.documentId, Key? key}) : super(key: key);

  @override
  State<EditMap> createState() => _EditMapState();
}

class _EditMapState extends State<EditMap> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl        = TextEditingController();
  final _addressCtrl     = TextEditingController();
  final _priceCtrl       = TextEditingController();
  final _carSlotCtrl     = TextEditingController();
  final _imageUrlCtrl    = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  // Dropdown state
  String? _selectedTag;
  final _tagOptions = ['EV', 'none'];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection('parking')
        .doc(widget.documentId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _nameCtrl.text        = data['nameparking'] ?? '';
      _addressCtrl.text     = data['address'] ?? '';
      _priceCtrl.text       = (data['price'] ?? '').toString();
      _carSlotCtrl.text     = (data['car_slot'] ?? '').toString();
      _imageUrlCtrl.text    = data['imageUrl'] ?? '';
      _descriptionCtrl.text = data['description'] ?? '';
      _selectedTag          = data['tag'] ?? _tagOptions.first;
    }

    setState(() => _loading = false);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('parking')
          .doc(widget.documentId)
          .update({
        'nameparking': _nameCtrl.text,
        'address':     _addressCtrl.text,
        'price':       int.tryParse(_priceCtrl.text) ?? 0,
        'car_slot':    int.tryParse(_carSlotCtrl.text) ?? 0,
        'imageUrl':    _imageUrlCtrl.text,
        'description': _descriptionCtrl.text,
        'tag':         _selectedTag,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated successfully!')),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Edit Parking')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Parking'),
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Name & Address Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Column(
                  children: [
                    _buildTextField(_nameCtrl, 'Parking Name', Icons.store),
                    SizedBox(height: 12),
                    _buildTextField(_addressCtrl, 'Address', Icons.location_on),
                  ],
                ),
              ),
            ),

            // Slots & Price Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _carSlotCtrl, 'Car Slots', Icons.directions_car,
                        keyboard: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        _priceCtrl, 'Price', Icons.attach_money,
                        keyboard: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Image Preview & URL
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              margin: EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  if (_imageUrlCtrl.text.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        _imageUrlCtrl.text,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: _buildTextField(
                      _imageUrlCtrl, 'Image URL', Icons.link,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),

            // Tag & Description Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              margin: EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedTag,
                      decoration: InputDecoration(
                        labelText: 'Tag',
                        prefixIcon: Icon(Icons.label),
                        border: OutlineInputBorder(),
                      ),
                      items: _tagOptions.map((tag) =>
                        DropdownMenuItem(value: tag, child: Text(tag))
                      ).toList(),
                      onChanged: (v) => setState(() => _selectedTag = v),
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      _descriptionCtrl, 'Description', Icons.description,
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Sticky Save Button
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: ElevatedButton.icon(
          icon: Icon(Icons.save),
          label: Text('Save Changes', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _saveChanges,
        ),
      ),
    );
  }

  // Helper to build inputs
  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter $label';
        if (keyboard == TextInputType.number && int.tryParse(v) == null)
          return 'Must be a number';
        return null;
      },
    );
  }
}
