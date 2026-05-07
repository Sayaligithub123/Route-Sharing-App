import 'package:flutter/material.dart';
import 'Driver_homepage.dart';

class DriverTripSummaryPage extends StatelessWidget {
  final String phone;
  DriverTripSummaryPage({required this.phone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),

      body: SafeArea(
        child: Column(
          children: [
            /// TOP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back, size: 16),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Trip Summary",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 32),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    /// 💰 TITLE
                    Text("💰", style: TextStyle(fontSize: 36)),
                    SizedBox(height: 8),
                    Text(
                      "Trip Complete!",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 16),

                    /// 🟢 TOTAL EARNINGS CARD
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A9E6E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total earned this trip",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "₹191",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              _earnerBox("₹143", "from Arjun"),
                              SizedBox(width: 16),
                              _earnerBox("₹48", "from Priya"),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 14),

                    /// 📊 TRIP DETAILS CARD
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        children: [
                          _fareRow("Route", "Station → Hadapsar"),
                          _fareRow("Distance", "8.4 km"),
                          _fareRow("Duration", "28 min"),
                          _fareRow("Passengers", "2 (shared)"),
                          Divider(height: 20),
                          _fareRowStrikethrough(
                            "Solo earnings would be",
                            "₹95",
                          ),
                          _fareRowGreen("Shared bonus earned", "+₹96"),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    /// ⭐ RATE PASSENGERS
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Rate your passengers",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),

                    SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _ratingBox(
                            "AP",
                            "Arjun",
                            Color(0xFFEDE9FE),
                            Color(0xFF5B21B6),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _ratingBox(
                            "PB",
                            "Priya",
                            Color(0xFFFEF3C7),
                            Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    /// 🚀 DONE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                         onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverHomeScreen(),
                    ),
                  );
                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1A9E6E),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          "Done → Back Home",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _earnerBox(String amount, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _fareRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareRowStrikethrough(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareRowGreen(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A9E6E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBox(
    String initials,
    String name,
    Color avatarBg,
    Color avatarFg,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: avatarBg,
            child: Text(
              initials,
              style: TextStyle(
                color: avatarFg,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text("⭐⭐⭐⭐⭐", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
