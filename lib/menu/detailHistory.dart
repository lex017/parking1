import 'package:flutter/material.dart';

class DetailHistory extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final Map<String, dynamic> paymentData;
  final String bookingDocId;

  const DetailHistory({
    Key? key,
    required this.bookingData,
    required this.paymentData,
    required this.bookingDocId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Custom text styles
    final titleStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    final detailTitleStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
    final detailTextStyle = TextStyle(
      fontSize: 16,
      color: Colors.black54,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('History Details'),
        backgroundColor: Colors.lightBlue,
      ),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ClipPath(
          clipper: TicketClipper(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              gradient: const LinearGradient(
                colors: [Colors.lightBlue, Colors.deepPurpleAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header area
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.lightBlue, Color.fromARGB(255, 3, 0, 155)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Parking Ticket',
                      style: titleStyle,
                    ),
                  ),
                ),
                // Dashed line divider
                CustomPaint(
                  size: const Size(double.infinity, 20),
                  painter: DashedLinePainter(),
                ),
                // Content area
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location: ${bookingData['nameparking'] ?? 'N/A'}',
                        style: detailTitleStyle,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.lightBlue),
                          const SizedBox(width: 8),
                          Text(
                            'Date: ${bookingData['bookingDate'] ?? 'N/A'}',
                            style: detailTextStyle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              color: Colors.lightBlue),
                          const SizedBox(width: 8),
                          Text(
                            'Time: ${bookingData['bookingTime'] ?? 'N/A'}',
                            style: detailTextStyle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.lightBlue),
                          const SizedBox(width: 8),
                          Text(
                            'Status: ${bookingData['Status'] ?? 'N/A'}',
                            style: detailTextStyle,
                          ),
                        ],
                      ),
                      const Divider(height: 30, thickness: 1),
                      Text(
                        'Payment Details',
                        style: detailTitleStyle,
                      ),
                      const SizedBox(height: 8),
                      PaymentDetailRow(
                        icon: Icons.monetization_on,
                        label: 'Amount',
                        value: '${paymentData['amount'] ?? 'N/A'}',
                      ),
                      PaymentDetailRow(
                        icon: Icons.date_range,
                        label: 'Payment Date',
                        value: '${paymentData['date'] ?? 'N/A'}',
                      ),
                      PaymentDetailRow(
                        icon: Icons.access_time,
                        label: 'Payment Time',
                        value: '${paymentData['time'] ?? 'N/A'}',
                      ),
                      PaymentDetailRow(
                        icon: Icons.payment,
                        label: 'Payment Status',
                        value: '${bookingData['paymentStatus'] ?? 'N/A'}',
                      ),
                      if (paymentData.containsKey('imageBill') &&
                          paymentData['imageBill'] != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Payment Image',
                          style: detailTitleStyle,
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullScreenImage(
                                  imageUrl: paymentData['imageBill'],
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              paymentData['imageBill'],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom widget for payment detail row.
class PaymentDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const PaymentDetailRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Colors.grey[800],
    );
    final valueStyle = TextStyle(
      fontSize: 16,
      color: Colors.black87,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.lightBlue),
          const SizedBox(width: 8),
          Text('$label: ', style: labelStyle),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

/// A custom clipper that gives a ticket-like shape with notches on the sides.
class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double notchRadius = 12.0;
    Path path = Path();
    // Start at top left
    path.moveTo(0, 0);
    // Top edge
    path.lineTo(size.width, 0);
    // Right edge with notch in the middle
    path.lineTo(size.width, size.height / 2 - notchRadius);
    path.arcToPoint(
      Offset(size.width, size.height / 2 + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(size.width, size.height);
    // Bottom edge
    path.lineTo(0, size.height);
    // Left edge with notch
    path.lineTo(0, size.height / 2 + notchRadius);
    path.arcToPoint(
      Offset(0, size.height / 2 - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Custom painter for drawing a dashed line.
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.0;

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

/// FullScreenImage displays the tapped image in full-screen mode.
class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Image View'),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
