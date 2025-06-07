import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parking1/chose/ownerMain.dart';
import 'package:parking1/model/ownerdata.dart';

class OwnerSave extends StatefulWidget {
  const OwnerSave({super.key});

  @override
  State<OwnerSave> createState() => _OwnerSaveState();
}

class _OwnerSaveState extends State<OwnerSave> {
  final formkey = GlobalKey<FormState>();
  OwnerPlace myOwner = OwnerPlace();
  final Future<FirebaseApp> firebase = Firebase.initializeApp();
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  File? _idCardImage;
  Uint8List? _profileBytes;
  Uint8List? _idCardBytes;
  String? _profileImageUrl;
  String? _idCardImageUrl;
  final TextEditingController expiryDateController = TextEditingController();
  CollectionReference _OwnerCollection =
      FirebaseFirestore.instance.collection("Owner");

  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";

  Future<void> _pickImage(bool isProfile) async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        if (kIsWeb) {
          final Uint8List bytes = await pickedFile.readAsBytes();
          setState(() {
            if (isProfile) {
              _profileBytes = bytes;
              _profileImage = null;
            } else {
              _idCardBytes = bytes;
              _idCardImage = null;
            }
          });
        } else {
          setState(() {
            if (isProfile) {
              _profileImage = File(pickedFile.path);
              _profileBytes = null;
            } else {
              _idCardImage = File(pickedFile.path);
              _idCardBytes = null;
            }
          });
        }
      }
    } catch (e) {
      print("Error selecting image: $e");
    }
  }

  Future<String?> _uploadImageToCloudinary(
      File? image, Uint8List? bytes) async {
    try {
      if (image == null && bytes == null) {
        return null;
      }

      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset;

      if (bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', bytes),
        );
      } else if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', image.path),
        );
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

 Widget ImagePickerWidget(bool isProfile) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // เพิ่ม padding ด้านข้าง
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isProfile ? "Upload Profile Picture" : "Upload ID Card",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pickImage(isProfile),
          child: Container(
            height: 180, // ขยายความสูงให้ใหญ่ขึ้นเล็กน้อย
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 8.0), // เพิ่ม margin ด้านข้าง
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1.5), // เพิ่มความหนาของเส้นขอบ
              borderRadius: BorderRadius.circular(16), // เพิ่มความโค้งมนให้มากขึ้น
              color: Colors.grey[200], // เพิ่มสีพื้นหลังอ่อน ๆ
            ),
            padding: const EdgeInsets.all(1.0), // เพิ่ม padding ด้านใน
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isProfile
                  ? (_profileBytes != null
                      ? Image.memory(_profileBytes!, fit: BoxFit.cover)
                      : _profileImage != null
                          ? Image.file(_profileImage!, fit: BoxFit.cover)
                          : const Center(
                              child: Text("Tap to upload", style: TextStyle(color: Colors.grey)),
                            ))
                  : (_idCardBytes != null
                      ? Image.memory(_idCardBytes!, fit: BoxFit.cover)
                      : _idCardImage != null
                          ? Image.file(_idCardImage!, fit: BoxFit.cover)
                          : const Center(
                              child: Text("Tap to upload", style: TextStyle(color: Colors.grey)),
                            )),
            ),
          ),
        ),
      ],
    ),
  );
}
Widget ExpiryDateInput() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: TextFormField(
      controller: expiryDateController,
      readOnly: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        labelText: 'BirthofDate',
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(
          Icons.calendar_today,
          color: Colors.black,
          size: 35.0,
        ),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );

        if (pickedDate != null) {
          String formattedDate =
              "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
          setState(() {
            expiryDateController.text = formattedDate;
          });
        }
      },
    ),
  );
}





 Widget SaveButton() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () async {
          final User? user = FirebaseAuth.instance.currentUser;

          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("User not logged in.")),
            );
            return;
          }

          String userEmail = user.email ?? "";

          if (formkey.currentState?.validate() ?? false) {
            formkey.currentState?.save();

            if (myOwner.fname.isEmpty ||
                myOwner.lname.isEmpty ||
                myOwner.age.isEmpty ||
                myOwner.idcard.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please fill all fields.")),
              );
              return;
            }

            try {
              _profileImageUrl =
                  await _uploadImageToCloudinary(_profileImage, _profileBytes);
              _idCardImageUrl =
                  await _uploadImageToCloudinary(_idCardImage, _idCardBytes);

              if (_profileImageUrl == null || _idCardImageUrl == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Image upload failed.")),
                );
                return;
              }

              final snapshot = await _OwnerCollection.get();
              final newOwnerId = "owner${snapshot.docs.length + 1}";

              await _OwnerCollection.doc(newOwnerId).set({
                "userId": user.uid,
                "email": userEmail,
                "fname": myOwner.fname,
                "lname": myOwner.lname,
                "age": myOwner.age,
                "idcard": myOwner.idcard,
                "Dateofbirth": expiryDateController.text,
                "verify": 'pending',
                "status": 'N/A',
                "profile_image_url": _profileImageUrl,
                "imageidenity": _idCardImageUrl,
                "created_at": Timestamp.now(),
              });

              formkey.currentState?.reset();

              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text("Waiting for verification..."),
                      ],
                    ),
                  );
                },
              );

              // Start listening for payment/verification status
              listenForPaymentStatus(newOwnerId);

            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error saving data: $e")),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please fill all fields correctly.")),
            );
          }
        },
        child: const Text(
          "Save",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
      ),
    ),
  );
}

// Listen for verification success
void listenForPaymentStatus(String newOwnerId) {
  FirebaseFirestore.instance
      .collection('Owner')
      .doc(newOwnerId)
      .snapshots()
      .listen((snapshot) {
    if (snapshot.exists && snapshot.data()?['verify'] == "success") {
      // Close the loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Navigate to ownerMain
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ownerMain(),
        ),
      );
    }
  });
}


  Widget showText() {
    return Text(
      "Data",
      style: TextStyle(
          fontSize: 35.0,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: 'Roboto'),
    );
  }

  Widget FnameInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextFormField(
        onSaved: (String? fname) {
          myOwner.fname = fname ?? '';
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          labelText: 'First Name',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            Icons.person,
            color: Colors.black,
            size: 35.0,
          ),
        ),
      ),
    );
  }

  Widget LnameInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextFormField(
        onSaved: (String? lname) {
          myOwner.lname = lname ?? '';
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          labelText: 'Last Name',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            Icons.person,
            color: Colors.black,
            size: 35.0,
          ),
        ),
      ),
    );
  }

  Widget AgeInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextFormField(
        onSaved: (String? age) {
          myOwner.age = age ?? '';
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          labelText: 'Age',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            Icons.cake,
            color: Colors.black,
            size: 35.0,
          ),
        ),
      ),
    );
  }

  Widget IDInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextFormField(
        onSaved: (String? idcard) {
          myOwner.idcard = idcard ?? '';
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          labelText: 'ID Card',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            Icons.credit_card,
            color: Colors.black,
            size: 35.0,
          ),
        ),
      ),
    );
  }

  // Widget SaveButton() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20.0),
  //     child: SizedBox(
  //       width: double.infinity,
  //       height: 50,
  //       child: ElevatedButton(
  //         onPressed: () async {
  //           final User? user = FirebaseAuth.instance.currentUser;

  //           if (user == null) {
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               const SnackBar(content: Text("User not logged in.")),
  //             );
  //             return;
  //           }

  //           String userEmail = user.email ?? "";

  //           if (formkey.currentState?.validate() ?? false) {
  //             formkey.currentState?.save();

  //             if (myOwner.fname.isEmpty ||
  //                 myOwner.lname.isEmpty ||
  //                 myOwner.age.isEmpty ||
  //                 myOwner.idcard.isEmpty) {
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(content: Text("Please fill all fields.")),
  //               );
  //               return;
  //             }

  //             try {
  //               final snapshot = await _OwnerCollection.get();
  //               final newOwnerId =
  //                   "owner${snapshot.docs.length + 1}"; // e.g., owner1, owner2, etc.

  //               await _OwnerCollection.doc(newOwnerId).set({
  //                 "email": userEmail,
  //                 "fname": myOwner.fname,
  //                 "lname": myOwner.lname,
  //                 "age": myOwner.age,
  //                 "idcard": myOwner.idcard,
  //                 "created_at": Timestamp.now(),
  //               });

  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(content: Text("Data saved successfully with ID: $newOwnerId")),
  //               );

  //               formkey.currentState?.reset();

  //               Navigator.pushReplacement(
  //                 context,
  //                 MaterialPageRoute(builder: (context) => ownerMain()),
  //               );
  //             } catch (e) {
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(content: Text("Error saving data: $e")),
  //               );
  //             }
  //           } else {
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               const SnackBar(content: Text("Please fill all fields correctly.")),
  //             );
  //           }
  //         },
  //         child: const Text(
  //           "Save",
  //           style: TextStyle(
  //             color: Colors.black,
  //             fontWeight: FontWeight.bold,
  //             fontSize: 20.0,
  //           ),
  //         ),
  //         style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: firebase,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Error"),
            ),
            body: Center(
              child: Text("Firebase initialization failed: ${snapshot.error}"),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            body: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Form(
                  key: formkey,
                  child: Column(
                    children: [
                      const SizedBox(height: 40.0),
                      showText(),
                      const SizedBox(height: 40.0),
                      FnameInput(),
                      const SizedBox(height: 20.0),
                      LnameInput(),
                      const SizedBox(height: 20.0),
                      AgeInput(),
                      const SizedBox(height: 20.0),
                      IDInput(),
                      const SizedBox(height: 20.0),
                      ExpiryDateInput(),
                      const SizedBox(height: 30.0),

                      ImagePickerWidget(true),
                      const SizedBox(height: 20.0),
                      ImagePickerWidget(false),
                      const SizedBox(height: 10.0),
                      SaveButton(),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
