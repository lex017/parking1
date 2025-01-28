import 'package:flutter/material.dart';

class put_Parking extends StatefulWidget {
  const put_Parking({super.key});

  @override
  State<put_Parking> createState() => _put_ParkingState();
}

class _put_ParkingState extends State<put_Parking> {


  List<String> data = ["Item 1", "Item 2", "Item 3"];

  void _addItem() {
    setState(() {
      data.add("New Item ${data.length + 1}");
    });
  }


  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _addItem,
            child: const Text("Add Item"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(data[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}