import 'package:flutter/material.dart';
import 'package:parking1/bottombar/maingPage.dart';
import 'package:parking1/drawer.dart';


class User_Parking extends StatefulWidget {
  const User_Parking({super.key});

  @override
  State<User_Parking> createState() => _User_ParkingState();
}

class _User_ParkingState extends State<User_Parking> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User'),
      ),
      
      body:const mainPage(),
      drawer: const drawer_menu(),
    );
  }
}