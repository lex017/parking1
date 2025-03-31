import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailMoney extends StatefulWidget {
  const DetailMoney({super.key});

  @override
  State<DetailMoney> createState() => _DetailMoneyState();
}

class _DetailMoneyState extends State<DetailMoney> {
  Future<Map<String, double>> fetchEarnings() async {
    // Fetch the bookings data
    QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance.collection('bookings').get();
    Map<String, int> bookingsData = {};

    // Fetch the payments data
    QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance.collection('payments').get();
    Map<String, double> earnings = {};

    // Calculate bookings per parking location
    for (var doc in bookingSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String location = data['nameparking'] ?? 'Unknown';
      int bookings = (data['bookings'] ?? 0).toInt();

      bookingsData[location] = (bookingsData[location] ?? 0) + bookings;
    }

    // Calculate earnings per parking location
    for (var doc in paymentSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String location = data['nameparking'] ?? 'Unknown';
      double amount = (data['amount'] ?? 0).toDouble();
      
      if (bookingsData.containsKey(location)) {
        int bookings = bookingsData[location]!;
        earnings[location] = (earnings[location] ?? 0) + (amount * bookings);
      }
    }

    return earnings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Earnings Overview")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, double>>(
          future: fetchEarnings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No earnings data available"));
            }

            final earningsData = snapshot.data!;
            final totalEarnings = earningsData.values.fold(0.0, (sum, element) => sum + element);
            final spots = earningsData.entries
                .map((e) => BarChartGroupData(
                      x: earningsData.keys.toList().indexOf(e.key),
                      barRods: [
                        BarChartRodData(
                          toY: e.value,
                          color: Colors.blue, // Set bar color here
                          width: 30, // Ensure the width is reasonable
                          borderRadius: BorderRadius.zero, // Optional: Adjust if needed
                        ),
                      ],
                    ))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Earnings by Parking Location",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: earningsData.values.reduce((a, b) => a > b ? a : b) + 1000,
                      barGroups: spots,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  earningsData.keys.toList()[value.toInt()],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Total Earnings: ${totalEarnings.toStringAsFixed(2)}/Kip",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
