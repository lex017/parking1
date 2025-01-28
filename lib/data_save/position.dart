import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class position extends StatefulWidget {
  const position({super.key});

  @override
  State<position> createState() => _PositionState();
}

class _PositionState extends State<position> {
  final formKey = GlobalKey<FormState>();
  String nameLocation = '';
  String location = '';
  String url = ''; // Variable to store URL
  final Future<FirebaseApp> firebase = Firebase.initializeApp();

  CollectionReference _locationCollection = FirebaseFirestore.instance.collection("Locations");

  // Fetch location data from Firestore for the current user
  Stream<DocumentSnapshot?> getUserLocationData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(null); // Return null if no user is logged in
    }

    return _locationCollection
        .where("email", isEqualTo: user.email)
        .limit(1) // Assuming one location per user
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return snapshot.docs.first; // Return the first document if found
          } else {
            return null; // Return null if no document is found
          }
        });
  }

  // Widget for displaying location name input form
  Widget nameLocationInput() {
    return SizedBox(
      width: 480,
      child: TextFormField(
        keyboardType: TextInputType.text,
        onSaved: (String? value) {
          nameLocation = value ?? '';
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a name for the location';
          }
          return null;
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          labelText: 'Location Name',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            Icons.location_city,
            color: Colors.black,
            size: 30.0,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
      ),
    );
  }

  // Widget for displaying location input form
  Widget locationInput() {
    return SizedBox(
      width: 480,
      child: TextFormField(
        keyboardType: TextInputType.text,
        onSaved: (String? value) {
          location = value ?? '';
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the location address';
          }
          return null;
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          labelText: 'Location Address',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            Icons.place,
            color: Colors.black,
            size: 30.0,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
      ),
    );
  }

  // Widget for displaying URL input form
  Widget urlInput() {
    return SizedBox(
      width: 480,
      child: TextFormField(
        keyboardType: TextInputType.url,
        onSaved: (String? value) {
          url = value ?? '';
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the location URL';
          }
          // You can add URL validation here if needed
          return null;
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          labelText: 'Location URL',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            Icons.link,
            color: Colors.black,
            size: 30.0,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
      ),
    );
  }

  // Save Button to store data in Firebase
  Widget saveButton() {
    return SizedBox(
      width: 150,
      height: 50,
      child: ElevatedButton(
        onPressed: () async {
          final User? user = FirebaseAuth.instance.currentUser;

          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("User not logged in.")),
            );
            return;
          }

          String userEmail = user.email ?? "";

          if (formKey.currentState?.validate() ?? false) {
            formKey.currentState?.save();

            // Ensure that location, name, and URL are not empty
            if (nameLocation.isEmpty || location.isEmpty || url.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Please fill all fields.")),
              );
              return;
            }

            try {
              // Save data to Firestore
              await _locationCollection.add({
                "email": userEmail,
                "nameLocation": nameLocation,
                "location": location,
                "url": url, // Saving URL along with other data
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Location saved successfully!")),
              );

              // Optionally, navigate to a different screen after saving data
              Navigator.pop(context);  // Navigate back to previous screen
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error saving data: $e")),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Please fill all fields correctly.")),
            );
          }
        },
        child: Text(
          "Save",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
            body: Center(child: Text("Firebase initialization failed: ${snapshot.error}")),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Location Input'),
              backgroundColor: Colors.white,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40.0),
                      Text(
                        "Enter Location Data",
                        style: TextStyle(
                          fontSize: 25.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      nameLocationInput(),
                      const SizedBox(height: 20.0),
                      locationInput(),
                      const SizedBox(height: 20.0),
                      urlInput(), // Add URL input form here
                      const SizedBox(height: 40.0),
                      saveButton(),
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
