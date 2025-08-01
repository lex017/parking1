import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parking1/chose/ownerMain.dart';
import 'package:parking1/menu/emp_main.dart';
import 'package:parking1/menu/employee_login.dart';
import 'package:parking1/model/employeedata.dart';
import 'package:easy_localization/easy_localization.dart'; // Import easy_localization

class emp_register extends StatefulWidget {
  final String ownerId;
  const emp_register({super.key, required this.ownerId});

  @override
  State<emp_register> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<emp_register> {
  bool obs = true;
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";
  void showMessage() {
    setState(() {
      obs = !obs;
    });
  }

  final formkey = GlobalKey<FormState>();
  Employee myUser = Employee();

  String? firstname;
  String? lastname;
  String? age;
  String? dateOfBirth;
  String? emp_id;
  String? password;
  String? selectedLocation;
  String? selectedGender;
  String? empProfile;

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
          SnackBar(content: Text('No_image_selected'.tr())), // Localized
        );
      }
    } catch (e) {
      print("Error selecting image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error_selecting_image'.tr())), // Localized
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

  Widget firstNameInput() {
    return SizedBox(
      width: 350,
      child: TextFormField(
        onSaved: (value) => firstname = value,
        validator: RequiredValidator(errorText: "Enter_first_name".tr()), // Localized
        decoration: InputDecoration(
          border: const UnderlineInputBorder(),
          labelText: 'First_Name'.tr(), // Localized
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.person, color: Colors.black, size: 35.0),
        ),
      ),
    );
  }

  Widget lastNameInput() {
    return SizedBox(
      width: 350,
      child: TextFormField(
        onSaved: (value) => lastname = value,
        validator: RequiredValidator(errorText: "Enter_last_name".tr()), // Localized
        decoration: InputDecoration(
          border: const UnderlineInputBorder(),
          labelText: 'Last_Name'.tr(), // Localized
          filled: true,
          fillColor: Colors.white,
          prefixIcon:
              const Icon(Icons.person_outline, color: Colors.black, size: 35.0),
        ),
      ),
    );
  }

  Widget ageInput() {
    return SizedBox(
      width: 350,
      child: TextFormField(
        onSaved: (value) => age = value,
        validator: RequiredValidator(errorText: "Enter_age".tr()), // Localized
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          border: const UnderlineInputBorder(),
          labelText: 'Age'.tr(), // Localized
          filled: true,
          fillColor: Colors.white,
          prefixIcon:
              const Icon(Icons.calendar_today, color: Colors.black, size: 35.0),
        ),
      ),
    );
  }

  // Updated empIdInput to allow user to enter their own ID
  Widget empIdInput() {
    return SizedBox(
      width: 350,
      child: TextFormField(
        onSaved: (value) => myUser.emp_id = value ?? '',
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Enter_employee_ID'.tr(); // Localized
          } else if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
            return 'Employee_ID_alphanumeric'.tr(); // Localized
          }
          return null;
        },
        decoration: InputDecoration(
          border: const UnderlineInputBorder(),
          labelText: 'Employee_ID'.tr(), // Localized
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.badge, color: Colors.black, size: 35.0),
        ),
      ),
    );
  }

  Widget signUpButton() {
    return SizedBox(
      width: 350,
      height: 50,
      child: ElevatedButton(
        onPressed: () async {
          if (formkey.currentState?.validate() ?? false) {
            formkey.currentState?.save();
            emp_id = myUser.emp_id;

            // Upload the image to Cloudinary and get the URL
            empProfile = await _uploadImageToCloudinary();

            if (emp_id != null && emp_id!.isNotEmpty) {
              try {
                await FirebaseFirestore.instance
                    .collection('employees')
                    .doc(emp_id)
                    .set({
                  'emp_id': emp_id,
                  'password': password,
                  'firstname': firstname,
                  'lastname': lastname,
                  'gender': selectedGender,
                  'age': age,
                  'locationId': selectedLocation,
                  'profileImage': empProfile, // ✅ Store the image URL here
                });

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ownerMain()),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Registration_failed'.tr(args: [e.toString()]))), // Localized with arg
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Employee_ID_required'.tr())), // Localized
              );
            }
          }
        },
        child: Text(
          "Register".tr(), // Localized
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
      ),
    );
  }

  Widget locationDropdown() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('parking')
      .where('ownerId',isEqualTo:widget.ownerId)
      .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        List<DropdownMenuItem<String>> items = snapshot.data!.docs.map((doc) {
          return DropdownMenuItem(
            value: doc.id,
            child: Text(doc['nameparking'] ?? 'Unknown_Location'.tr()), // Localized
          );
        }).toList();
        return SizedBox(
          width: 350,
          child: DropdownButtonFormField<String>(
            value: selectedLocation,
            hint: Text('Select_Location_ID'.tr()), // Localized
            items: items,
            onChanged: (value) {
              setState(() {
                selectedLocation = value;
              });
            },
            validator: (value) =>
                value == null ? 'Please_select_location'.tr() : null, // Localized
            decoration: InputDecoration(
              border: const UnderlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              prefixIcon:
                  const Icon(Icons.location_on, color: Colors.black, size: 35.0),
            ),
          ),
        );
      },
    );
  }

  Widget genderDropdown() {
    return SizedBox(
      width: 350,
      child: DropdownButtonFormField<String>(
        value: selectedGender,
        hint: Text('Select_Gender'.tr()), // Localized
        items: [
          DropdownMenuItem(value: 'Male', child: Text('Male'.tr())), // Localized
          DropdownMenuItem(value: 'Female', child: Text('Female'.tr())), // Localized
          DropdownMenuItem(value: 'Other', child: Text('Other'.tr())), // Localized
        ],
        onChanged: (value) {
          setState(() {
            selectedGender = value;
          });
        },
        validator: (value) => value == null ? 'Please_select_gender'.tr() : null, // Localized
        decoration: InputDecoration(
          border: const UnderlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.transgender, color: Colors.black, size: 35.0),
        ),
      ),
    );
  }

  Widget empProfileWidget() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(16),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : _imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : Center(
                    child: Text(
                      "Tap_to_upload_image".tr(), // Localized
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
      ),
    );
  }
Widget passwordInput() {
  return SizedBox(
    width: 350,
    child: TextFormField(
      obscureText: obs,
      onSaved: (value) => password = value,
      validator: MultiValidator([
        RequiredValidator(errorText: "Enter_password".tr()), // Localized
        MinLengthValidator(6, errorText: "Password_min_length".tr()), // Localized
      ]),
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        labelText: 'Password'.tr(), // Localized
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.lock, color: Colors.black, size: 35.0),
        suffixIcon: IconButton(
          icon: Icon(
            obs ? Icons.visibility_off : Icons.visibility,
            color: Colors.black,
          ),
          onPressed: showMessage,
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Sign_up_Employee".tr()), // Localized
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: const BoxDecoration(color: Colors.white),
                child: Form(
                  key: formkey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 10.0),
                            firstNameInput(),
                            const SizedBox(height: 20.0),
                            lastNameInput(),
                            const SizedBox(height: 20.0),
                            ageInput(),
                            const SizedBox(height: 20.0),

                            empIdInput(),
                            const SizedBox(height: 20.0),
                            passwordInput(),
                            const SizedBox(height: 20.0),
                            locationDropdown(),
                            const SizedBox(height: 20.0),
                            genderDropdown(),
                            const SizedBox(height: 20.0),
                            empProfileWidget(),
                            const SizedBox(height: 30.0),
                            signUpButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}