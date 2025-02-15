import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BuyTicket extends StatefulWidget {
  const BuyTicket({super.key});

  @override
  State<BuyTicket> createState() => _BuyTicketState();
}

class _BuyTicketState extends State<BuyTicket> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 300,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.yellow[700],
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 5, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "PARKING TICKET",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),
              Icon(Icons.local_parking, size: 50, color: Colors.black),
              SizedBox(height: 10),
              QrImageView(
                data: "ParkingTicket12345",
                version: QrVersions.auto,
                size: 120,
              ),
              SizedBox(height: 10),
              Text("THANK YOU AND LUCKY ROAD!", style: TextStyle(fontSize: 14)),
              Divider(thickness: 1, color: Colors.black),
              Text("17/05/2023", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("From:", style: TextStyle(fontSize: 16)),
                      
                    ],
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("11:23 AM", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text("PAID: \$5.25", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Text("PARKING TICKET", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
