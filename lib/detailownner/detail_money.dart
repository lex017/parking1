import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DetailMoney extends StatefulWidget {
  const DetailMoney({super.key});

  @override
  State<DetailMoney> createState() => _DetailMoneyState();
}

class _DetailMoneyState extends State<DetailMoney> {
  String selectedParking = 'All';
  List<String> parkingOptions = ['All'];
  Set<String> ownerParkingNames = {};

  late Future<Map<String, double>> earningsFuture;
  late Future<int> ticketCountFuture;

  List<String> dayLabels = [];

  DateTime startDate = DateTime.now().subtract(const Duration(days: 9));
  DateTime endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchParkingOptions();
    loadData();
  }

  void loadData() {
    earningsFuture = fetchEarningsByDate(startDate, endDate);
    ticketCountFuture = fetchTicketCount(startDate, endDate);
  }

  Future<void> fetchParkingOptions() async {
    try {
      final String ownerId = FirebaseAuth.instance.currentUser?.uid ?? '';
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('parking')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      final names = snapshot.docs
          .map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data['nameparking'] ?? 'Unknown';
          })
          .cast<String>()
          .toSet();

      setState(() {
        parkingOptions = ['All', ...names.toList()];
        ownerParkingNames = names;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<Map<String, double>> fetchEarningsByDate(
      DateTime start, DateTime end) async {
    Map<String, double> earningsByDay = {};

    final daysCount = end.difference(start).inDays + 1;
    final List<DateTime> daysList =
        List.generate(daysCount, (i) => start.add(Duration(days: i)));

    dayLabels =
        daysList.map((date) => DateFormat('d MMM').format(date)).toList();

    for (var label in dayLabels) {
      earningsByDay[label] = 0;
    }

    try {
      final bookingsSnapshot =
          await FirebaseFirestore.instance.collection('bookings').get();

      final bookingMap = {
        for (var doc in bookingsSnapshot.docs)
          doc.id: {
            'nameparking': (doc.data() as Map<String, dynamic>)['nameparking'],
            'locationId': (doc.data() as Map<String, dynamic>)['locationId']
          }
      };

      final paymentSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('status', isEqualTo: 'success')
          .get();

      for (var doc in paymentSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp? ts = data['timestamp'];
        final String? bookingId = data['bookingId'];

        double amount = (data['amount'] is String)
            ? double.tryParse(data['amount']) ?? 0
            : (data['amount'] as num).toDouble();

        if (ts != null &&
            bookingId != null &&
            bookingMap.containsKey(bookingId)) {
          final dt = ts.toDate();
          if (!dt.isBefore(start) && !dt.isAfter(end)) {
            final label = DateFormat('d MMM').format(dt);
            final bookingInfo = bookingMap[bookingId]!;
            final parkingName = bookingInfo['nameparking'] ?? 'Unknown';

            if (dayLabels.contains(label) &&
                (selectedParking == 'All'
                    ? ownerParkingNames.contains(parkingName)
                    : selectedParking == parkingName)) {
              earningsByDay[label] = earningsByDay[label]! + amount;
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching earnings: $e");
    }

    return earningsByDay;
  }

  Future<int> fetchTicketCount(DateTime start, DateTime end) async {
    int ticketCount = 0;

    try {
      final bookingsSnapshot =
          await FirebaseFirestore.instance.collection('bookings').get();

      final bookingMap = {
        for (var doc in bookingsSnapshot.docs)
          doc.id: {
            'nameparking': (doc.data() as Map<String, dynamic>)['nameparking'],
            'locationId': (doc.data() as Map<String, dynamic>)['locationId']
          }
      };

      final paymentSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('status', isEqualTo: 'success')
          .get();

      for (var doc in paymentSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp? ts = data['timestamp'];
        final String? bookingId = data['bookingId'];

        if (ts != null &&
            bookingId != null &&
            bookingMap.containsKey(bookingId)) {
          final dt = ts.toDate();
          final parkingName =
              bookingMap[bookingId]?['nameparking'] ?? 'Unknown';

          if (!dt.isBefore(start) &&
              !dt.isAfter(end) &&
              (selectedParking == 'All'
                  ? ownerParkingNames.contains(parkingName)
                  : selectedParking == parkingName)) {
            ticketCount++;
          }
        }
      }
    } catch (e) {
      print("Error counting tickets: $e");
    }

    return ticketCount;
  }

  Future<void> pickStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: endDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blueAccent,
            hintColor: Colors.blueAccent,
            primaryColorDark: Colors.blueAccent,
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
        if (startDate.isAfter(endDate)) {
          endDate = startDate;
        }
        loadData();
      });
    }
  }

  Future<void> pickEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blueAccent,
            hintColor: Colors.blueAccent,
            primaryColorDark: Colors.blueAccent,
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
        loadData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ປະຫວັດການຈ່າຍ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blueAccent[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.shade200),
              ),
              child: DropdownButton<String>(
                value: selectedParking,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: parkingOptions
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedParking = value!;
                    loadData();
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // Date range pickers
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _datePickerButton('Start Date', startDate, pickStartDate),
                const SizedBox(width: 20),
                _datePickerButton('End Date', endDate, pickEndDate),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: FutureBuilder<Map<String, double>>(
                future: earningsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data!;
                  final total = data.values.fold(0.0, (a, b) => a + b);

                  final chartData = dayLabels.asMap().entries.map((entry) {
                    int i = entry.key;
                    String label = entry.value;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data[label] ?? 0,
                          color: Colors.blueAccent.shade400,
                          width: 22,
                          borderRadius: BorderRadius.circular(8),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: total == 0 ? 10 : total + total * 0.3,
                            color: Colors.blueAccent.shade100,
                          ),
                        ),
                      ],
                    );
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 280,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            child: SizedBox(
                              width: chartData.length * 70,
                              child: BarChart(
                                BarChartData(
                                  maxY: total == 0 ? 10 : total + total * 0.3,
                                  barGroups: chartData,
                                  borderData: FlBorderData(show: false),
                                  gridData: FlGridData(
                                      show: true, drawVerticalLine: false),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 38,
                                        interval: total == 0
                                            ? 1
                                            : (total / 5).ceilToDouble(),
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            NumberFormat.compact()
                                                .format(value),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        getTitlesWidget: (value, meta) {
                                          int index = value.toInt();
                                          if (index < 0 ||
                                              index >= dayLabels.length)
                                            return const SizedBox.shrink();
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Text(
                                              dayLabels[index],
                                              style: const TextStyle(
                                                color: Colors.blueAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Summary cards
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _infoCardkip(
                            icon: Image.asset(
                              'assets/images/kip.png',
                              width: 32,
                              height: 32,
                              color:
                                  Colors.green.shade600, // optional color tint
                            ),
                            title: 'ລາຍຮັບ',
                            value: NumberFormat("#,##0").format(total),
                            color: Colors.green.shade600,
                            width: MediaQuery.of(context).size.width * 0.42,
                          ),
                          FutureBuilder<int>(
                            future: ticketCountFuture,
                            builder: (context, snapshot) {
                              int count = snapshot.data ?? 0;
                              return _infoCard(
                                icon: Icons.confirmation_num,
                                title: 'ປີ້ລວມ',
                                value: '$count',
                                color: Colors.blue.shade600,
                                width: MediaQuery.of(context).size.width * 0.42,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100],
    );
  }

  Widget _datePickerButton(String label, DateTime date, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent.shade100,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
      label: Text(
        DateFormat('yyyy-MM-dd').format(date),
        style: const TextStyle(
            fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _infoCardkip({
  required Widget icon,
  required String title,
  required String value,
  required Color color,
  required double width,
}) {
  return Container(
    width: width,
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}
