import 'package:flutter/material.dart';
import 'package:parking1/bottombar/chatPage.dart';
import 'package:parking1/bottombar/questionpage.dart';
import 'package:parking1/drawer.dart';


class Help extends StatefulWidget {
  const Help({super.key});

  @override
  State<Help> createState() => _HelpState();
}

class _HelpState extends State<Help> {

 Widget questionButton() {
  return SizedBox(
    width: 300,
    height: 50,
    child: ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop(); 
        MaterialPageRoute route =
            MaterialPageRoute(builder: (c) => QuestionPage());
        Navigator.of(context).push(route);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
      ),
      child: const Text(
        "Question",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20.0,
        ),
      ),
    ),
  );
}


  Widget chatButton() {
    return SizedBox(
      width: 300,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
         Navigator.of(context).pop();
                MaterialPageRoute route =
                    MaterialPageRoute(builder: (c) => ChatPage(bookingId: '',));
                Navigator.of(context).push(route);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 0, 121, 227), // Custom button color
        ),
        child: const Text(
          "Chat",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
      ),
    );
  }

  
  // Widget historyButton() {
  //   return SizedBox(
  //     width: 300,
  //     height: 50,
  //     child: ElevatedButton(
  //       onPressed: () {
  //       },
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: const Color.fromARGB(255, 255, 255, 255), 
  //       ),
  //       child: const Text(
  //         "History",
  //         style: TextStyle(
  //           color: Colors.black,
  //           fontWeight: FontWeight.bold,
  //           fontSize: 20.0,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help"),
        centerTitle: true, 
      ),
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 221, 221, 221),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              chatButton(),
              const SizedBox(height: 20.0),
              questionButton(),
              const SizedBox(height: 20.0),
              // historyButton(),
            ],
          ),
        ),
      ),

    );
  }
}
