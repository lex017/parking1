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
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    fetchParkingOptions();
  }

  Future<void> fetchParkingOptions() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('bookings').get();
      final names = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return data['nameparking'] ?? 'Unknown';
      }).toSet();

      setState(() {
        parkingOptions = ['All', ...names.cast<String>()];
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<Map<String, double>> fetchEarningsByRange() async {
    Map<String, double> earningsByDay = {
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };

    if (selectedDateRange == null) return earningsByDay;

    try {
      QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('status', isEqualTo: 'success')
          .get();

      for (var doc in paymentSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double amount = (data['amount'] is String)
            ? double.tryParse(data['amount']) ?? 0
            : (data['amount'] as num).toDouble();

        Timestamp? ts = data['timestamp'];
        String? userId = data['userId'];

        if (ts != null && userId != null) {
          DateTime dt = ts.toDate();
          String weekday = DateFormat('E').format(dt);

          var bookingDocs = await FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

          String parkingName = bookingDocs.docs.isNotEmpty
              ? (bookingDocs.docs.first.data()
                      as Map<String, dynamic>)['nameparking'] ??
                  'Unknown'
              : 'Unknown';

          if ((selectedParking == 'All' || selectedParking == parkingName) &&
              !dt.isBefore(selectedDateRange!.start) &&
              !dt.isAfter(selectedDateRange!.end)) {
            if (earningsByDay.containsKey(weekday)) {
              earningsByDay[weekday] = earningsByDay[weekday]! + amount;
            }
          }
        }
      }
    } catch (e) {
      print("Error: $e");
    }

    return earningsByDay;
  }

  Future<void> selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
    }
  }

  Future<int> fetchTicketCount() async {
    int ticketCount = 0;

    if (selectedDateRange == null) return ticketCount;

    try {
      QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('status', isEqualTo: 'success')
          .get();

      for (var doc in paymentSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        Timestamp? ts = data['timestamp'];
        String? userId = data['userId'];

        if (ts != null && userId != null) {
          DateTime dt = ts.toDate();

          if (dt.isBefore(selectedDateRange!.start) ||
              dt.isAfter(selectedDateRange!.end)) {
            continue;
          }

          // Match to booking
          var bookingDocs = await FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

          String parkingName = bookingDocs.docs.isNotEmpty
              ? (bookingDocs.docs.first.data()
                      as Map<String, dynamic>)['nameparking'] ??
                  'Unknown'
              : 'Unknown';

          if (selectedParking == 'All' || selectedParking == parkingName) {
            ticketCount++;
          }
        }
      }
    } catch (e) {
      print('Error fetching ticket count: $e');
    }

    return ticketCount;
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackButton(),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                "ປະຫວັດການຈ່າຍ",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  value: selectedParking,
                  isExpanded: true,
                  underline: Container(),
                  items: parkingOptions.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => selectedParking = value!),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDateRange == null
                        ? "ເລືອກຊ່ວງວັນທີ"
                        : "ຈາກ: ${DateFormat('yyyy-MM-dd').format(selectedDateRange!.start)} ຫາ: ${DateFormat('yyyy-MM-dd').format(selectedDateRange!.end)}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue, // Icon and label color
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () => selectDateRange(context),
                  icon: const Icon(Icons.date_range,color: Colors.white,),
                  label: const Text(
                    "ເລືອກວັນ",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<Map<String, double>>(
                future: fetchEarningsByRange(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: Text("No data found"));
                  }

                  final data = snapshot.data!;
                  final total = data.values.fold(0.0, (a, b) => a + b);
                  final chartData = weekDays.asMap().entries.map((entry) {
                    int i = entry.key;
                    String day = entry.value;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data[day] ?? 0,
                          color: Colors.greenAccent.shade700,
                          width: 18,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    );
                  }).toList();

                  return Column(
                    children: [
                      SizedBox(
                        height: 250,
                        child: BarChart(
                          BarChartData(
                            maxY: total < 10 ? 10 : total + total * 0.1,
                            barGroups: chartData,
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    return Text(
                                      weekDays[index],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: Colors.green.shade100,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 16),
                                child: Column(
                                  children: [
                                    const Icon(Icons.attach_money,
                                        color: Colors.green, size: 32),
                                    const SizedBox(height: 8),
                                    const Text("Money"),
                                    Text(
                                      NumberFormat("#,##0").format(total),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Card(
                              color: Colors.blue.shade100,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 16),
                                child: FutureBuilder<int>(
                                  future: fetchTicketCount(),
                                  builder: (context, snapshot) {
                                    final ticketCount = snapshot.data ?? 0;
                                    return Column(
                                      children: [
                                        const Icon(Icons.confirmation_num,
                                            color: Colors.blue, size: 32),
                                        const SizedBox(height: 8),
                                        const Text("Tickets"),
                                        Text(
                                          "$ticketCount",
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
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
    );
  }
}
