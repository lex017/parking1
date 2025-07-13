import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingDetailPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailPage({super.key, required this.booking});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  Map<String, dynamic>? paymentData;
  bool isLoading = true;

  final Color primaryBlue = const Color(0xFF4361EE);

  @override
  void initState() {
    super.initState();
    fetchPaymentData();
  }

  Future<void> fetchPaymentData() async {
    try {
      final bookingId = widget.booking['id'] ?? widget.booking['bookingId'];
      final snapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          paymentData = snapshot.docs.first.data();
        });
      }
    } catch (e) {
      debugPrint("Error fetching payment data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _openFullImage(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: InteractiveViewer(
            minScale: 0.1,
            maxScale: 4.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(40),
                  child: const Icon(Icons.broken_image, size: 80, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final ts = booking['timestamp']?.toDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Booking Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Colors.blue
          ),
        ),
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FA), Color(0xFFE4EDFB)],
            stops: [0.1, 0.9],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView(
            children: [
              _buildBookingCard(booking, ts),
              const SizedBox(height: 16),
              _buildPaymentCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, DateTime? ts) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF9FBFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.directions_car, color: primaryBlue, size: 28),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Vehicle Information",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E2C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.person, "User", booking['userName']),
            _buildInfoRow(Icons.local_parking, "Parking", booking['nameparking']),
            _buildInfoRow(Icons.location_on, "Province", booking['province']),
            _buildInfoRow(Icons.confirmation_number, "Plate",
                "${booking['charplate']} ${booking['numberplate']}"),
            _buildInfoRow(Icons.category, "Type", booking['typeplate']),
            _buildInfoRow(Icons.color_lens, "Color", booking['color']),
            _buildInfoRow(Icons.info, "Status", booking['Status'],
                valueColor: _getStatusColor(booking['Status'])),
            _buildInfoRow(Icons.calendar_today, "Date",
                ts != null ? DateFormat('yyyy-MM-dd HH:mm').format(ts) : "Unknown"),
            const SizedBox(height: 20),
            if (booking['image'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Vehicle Image",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E2C),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _openFullImage(booking['image']),
                    child: _roundedImage(booking['image']),
                  ),
                ],
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF5F0FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A4C93).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.payment, color: Color(0xFF6A4C93), size: 28),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Payment Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E2C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                  ),
                ),
              )
            else if (paymentData != null)
              ..._buildPaymentInfo(paymentData!)
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "No payment data found",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.blueGrey[600], size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4), children: [
              TextSpan(text: "$title: ", style: const TextStyle(fontWeight: FontWeight.w500)),
              TextSpan(
                  text: value,
                  style: TextStyle(
                    color: valueColor ?? const Color(0xFF555770),
                    fontWeight: FontWeight.w400,
                  )),
            ]),
          ),
        ),
      ]),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return const Color(0xFF555770);
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF0BAB64);
      case 'pending':
        return const Color(0xFFFFA500);
      case 'cancelled':
        return const Color(0xFFFF3B3B);
      default:
        return const Color(0xFF555770);
    }
  }

  Widget _roundedImage(String url) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openFullImage(url),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  url,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                          color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    decoration: BoxDecoration(
                        color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.zoom_in, size: 50, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  List<Widget> _buildPaymentInfo(Map<String, dynamic> p) {
    return [
      _buildInfoRow(Icons.receipt, "Status", p['status'], valueColor: _getStatusColor(p['status'])),
      _buildInfoRow(Icons.attach_money, "Amount", p['amount'].toString()),
      _buildInfoRow(Icons.date_range, "Date", "${p['date']} ${p['time']}"),
      _buildInfoRow(Icons.directions_car, "Vehicle", p['vechicle']),
      const SizedBox(height: 20),
      if (p['imageBill'] != null)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Payment Receipt",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E2C),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _openFullImage(p['imageBill']),
              child: _roundedImage(p['imageBill']),
            ),
          ],
        ),
    ];
  }
}
