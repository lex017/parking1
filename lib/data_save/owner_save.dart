import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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

  CollectionReference _OwnerCollection =
      FirebaseFirestore.instance.collection("Owner");

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
    return SizedBox(
      width: 480,
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
            )),
      ),
    );
  }

  Widget LnameInput() {
    return SizedBox(
      width: 480,
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
            )),
      ),
    );
  }

  Widget AgeInput() {
    return SizedBox(
      width: 480,
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
            )),
      ),
    );
  }

  Widget IDInput() {
    return SizedBox(
      width: 480,
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
            )),
      ),
    );
  }

  Widget SaveButton() {
    return SizedBox(
      width: 120,
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
              // Get the total number of documents to generate a custom ID
              final snapshot = await _OwnerCollection.get();
              final newOwnerId =
                  "owner${snapshot.docs.length + 1}"; // e.g., owner1, owner2, etc.

              await _OwnerCollection.doc(newOwnerId).set({
                "email": userEmail,
                "fname": myOwner.fname,
                "lname": myOwner.lname,
                "age": myOwner.age,
                "idcard": myOwner.idcard,
                "created_at":
                    Timestamp.now(), // Optional: Track when data was saved
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text("Data saved successfully with ID: $newOwnerId")),
              );

              formkey.currentState?.reset();

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ownerMain()),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error saving data: $e")),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Please fill all fields correctly.")),
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
    );
  }

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
                child:
                    Text("Firebase initialization failed: ${snapshot.error}")),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            body: Center(
              child: SingleChildScrollView(
                // Wrap content inside a SingleChildScrollView
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Form(
                    key: formkey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                        const SizedBox(
                            height:
                                20.0), // Adjusted the space for better balance
                        SaveButton(),
                      ],
                    ),
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
