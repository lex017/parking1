import 'package:flutter/material.dart';
import 'package:parking1/drawer.dart';


class history extends StatefulWidget {
  const history({super.key});

  @override
  State<history> createState() => _HistoryState();
}

class _HistoryState extends State<history> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const TicketWidget(
            title: 'Parking Ticket',
            subtitle: 'Location: Downtown Parking Lot',
            date: '19 Nov 2024',
            seat: 'Slot 25B',
          ),
          const TicketWidget(
            title: 'Parking Ticket',
            subtitle: 'Location: City Mall',
            date: '18 Nov 2024',
            seat: 'Slot 12A',
          ),
          const TicketWidget(
            title: 'Parking Ticket',
            subtitle: 'Location: Airport Parking',
            date: '17 Nov 2024',
            seat: 'Slot 42C',
          ),
        ],
      ),
      drawer: const drawer_menu(),
    );
  }
}

class TicketWidget extends StatelessWidget {
  final String title;
  final String subtitle;   
  final String date;
  final String seat;

  const TicketWidget({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.seat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top part of the ticket
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.local_parking, color: Colors.white),
              ],
            ),
          ),
          // Perforation line
          CustomPaint(
            size: const Size(double.infinity, 20),
            painter: DashedLinePainter(),
          ),
          // Bottom part of the ticket
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date'),
                        Text(
                          date,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Slot'),
                        Text(
                          seat,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
