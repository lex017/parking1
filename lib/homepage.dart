import 'package:flutter/material.dart';
import 'package:parking1/bottombar/chatPage.dart';
import 'package:parking1/bottombar/historyPage.dart';
import 'package:parking1/bottombar/maingPage.dart';
import 'package:parking1/bottombar/profilePage.dart';
import 'package:parking1/drawer.dart';


const List screenPage = [mainPage(), ChatPage(), HistoryPage(), ProfilePage()];

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HOME',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: mainPage(),
      drawer: const drawer_menu(),
    );
  }
}
