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
    // Fetch bookings to map user IDs to parking names
    QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance.collection('bookings').get();
    Map<String, String> userToParking = {}; // Maps userId to parking name

    for (var doc in bookingSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String userId = data['userId'] ?? '';
      String nameParking = data['nameparking'] ?? 'Unknown';

      userToParking[userId] = nameParking;
    }

    // Fetch payments and calculate earnings per parking location
    QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('status', isEqualTo: 'success')
        .get();

    Map<String, double> earningsByParking = {};

    for (var doc in paymentSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String userId = data['userId'] ?? '';
      double amount = double.tryParse(data['amount'] ?? '0') ?? 0; // Convert string to double

      // Find the corresponding parking name
      String parkingName = userToParking[userId] ?? 'Unknown';

      earningsByParking[parkingName] = (earningsByParking[parkingName] ?? 0) + amount;
    }

    return earningsByParking;
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
            final List<String> locations = earningsData.keys.toList();
            final double totalEarnings = earningsData.values.fold(0, (sum, amount) => sum + amount);

            final List<BarChartGroupData> spots = locations.asMap().entries.map((entry) {
              int index = entry.key;
              String location = entry.value;
              double earnings = earningsData[location] ?? 0;

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: earnings,
                    color: Colors.blue,
                    width: 30,
                    borderRadius: BorderRadius.zero,
                  ),
                ],
              );
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Earnings by Parking Location",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                // Bar Chart Widget
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: totalEarnings + 1000, // Ensure maxY is slightly above highest earnings
                      barGroups: spots,
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < locations.length) {
                                return Transform.rotate(
                                  angle: -0.5,
                                  child: Text(
                                    locations[value.toInt()],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Total Earnings Card
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          "Total Earnings",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "₭${totalEarnings.toStringAsFixed(2)}", 
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
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
