import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parking1/chose/ownerMain.dart';
import 'package:parking1/data_save/owner_save.dart';
import 'package:parking1/drawer.dart';



class Owner extends StatefulWidget {
  const Owner({super.key});

  @override
  State<Owner> createState() => _OwnerState();
}

class _OwnerState extends State<Owner> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _ownerCollection =
      FirebaseFirestore.instance.collection("Owner");

  
  Future<bool> checkDataExists() async {
    try {
      final User? user = _auth.currentUser; 
      if (user == null) return false;      

      String userEmail = user.email ?? "";

      
      QuerySnapshot snapshot = await _ownerCollection
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty; 
    } catch (e) {
      print("Error checking data: $e");
      return false;
    }
  }

  
  void navigateBasedOnData(bool dataExists) {
    if (dataExists) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ownerMain()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OwnerSave()),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    checkDataExists().then((dataExists) {
      navigateBasedOnData(dataExists);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner')),
      body: const Center(child: CircularProgressIndicator()),
      drawer: const drawer_menu(),
    );
  }
}

