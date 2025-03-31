import 'package:flutter/material.dart';
import 'package:parking1/bottombar/maingPage.dart';
import 'package:parking1/drawer.dart';
import 'package:parking1/map_api/LocationPage.dart';
import 'package:parking1/menu/myTicket.dart';
import 'package:parking1/menu/setting.dart';

const List<Widget> screenPages = [
  mainPage(),
  LocationPage(),
  MyTicket(),
  SettingPage(),
];

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int selectIdx = 0;

  void onTabTapped(int idx) {
    setState(() {
      selectIdx = idx;
    });
  }

  Widget BNavigateBar(int selectIdx, Function(int) onTabTapped) {
  return Container(
    height: 100,
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Colors.black,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(25),
        topRight: Radius.circular(25),
      ),
      // boxShadow: [
      //   BoxShadow(
      //     color: Colors.black.withOpacity(0.2),
      //     blurRadius: 10,
      //     spreadRadius: 2,
      //   ),
      // ],
    ),
    child: ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(25),
        topRight: Radius.circular(25),
      ),
      child: BottomNavigationBar(
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Theme.of(context).brightness == Brightness.light
            ? Colors.grey
            : Colors.white70,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Colors.black,
        currentIndex: selectIdx,
        onTap: onTabTapped,
        selectedLabelStyle: const TextStyle(
          fontSize: 15.0, fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home, color: Colors.blueAccent),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            activeIcon: Icon(Icons.location_searching, color: Colors.blueAccent),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            activeIcon: Icon(Icons.confirmation_number_outlined, color: Colors.blueAccent),
            label: 'Myticket',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            activeIcon: Icon(Icons.person, color: Colors.blueAccent),
            label: 'Settings',
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screenPages[selectIdx],
      drawer: const drawer_menu(),
      bottomNavigationBar: BNavigateBar(selectIdx, onTabTapped),
    );
  }
}
