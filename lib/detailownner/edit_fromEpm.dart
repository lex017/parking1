import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditEmployeeForm extends StatefulWidget {
  final Map<String, dynamic> employee;

  const EditEmployeeForm({super.key, required this.employee});

  @override
  State<EditEmployeeForm> createState() => _EditEmployeeFormState();
}

class _EditEmployeeFormState extends State<EditEmployeeForm> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _ageController;
  late TextEditingController _genderController;
  late TextEditingController _empIdController;

  @override
  void initState() {
    super.initState();
    _firstnameController = TextEditingController(text: widget.employee['firstname']);
    _lastnameController = TextEditingController(text: widget.employee['lastname']);
    _ageController = TextEditingController(text: widget.employee['age']);
    _genderController = TextEditingController(text: widget.employee['gender']);
    _empIdController = TextEditingController(text: widget.employee['emp_id']);
  }

  void saveChanges() async {
    if (_formKey.currentState!.validate()) {
      await _firestore.collection('employees').doc(widget.employee['id']).update({
        'firstname': _firstnameController.text,
        'lastname': _lastnameController.text,
        'age': _ageController.text,
        'gender': _genderController.text,
        'emp_id': _empIdController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Employee updated successfully!')),
      );

      Navigator.pop(context); // Go back
    }
  }

  Widget buildTextField(
      {required TextEditingController controller, required String label, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        keyboardType: keyboardType,
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Employee'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Employee Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  buildTextField(controller: _firstnameController, label: 'First Name'),
                  buildTextField(controller: _lastnameController, label: 'Last Name'),
                  buildTextField(controller: _ageController, label: 'Age', keyboardType: TextInputType.number),
                  buildTextField(controller: _genderController, label: 'Gender'),
                  buildTextField(controller: _empIdController, label: 'Employee ID'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      onPressed: saveChanges,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
