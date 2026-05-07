import 'package:flutter/material.dart';
import 'driver_trip_summary_page.dart';


class MultiPassengerRidePage extends StatelessWidget {
  final String phone;
  MultiPassengerRidePage({required this.phone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            /// 🗺 MAP AREA
            Container(
              height: 220,
              color: Color(0xFFE8F0E8),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 150,
                    child: Container(width: 6, color: Colors.white),
                  ),
                  Positioned(
                    top: 110,
                    left: 0,
                    right: 0,
                    child: Container(height: 6, color: Colors.white),
                  ),
                  Positioned(
                    top: 97,
                    left: 138,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(0xFF1A9E6E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text("🚗", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 25,
                    left: 210,
                    child: Icon(
                      Icons.location_on,
                      color: Color(0xFF1A9E6E),
                      size: 28,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A9E6E).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "2 passengers aboard",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// 🔽 CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    /// 👥 PASSENGER CARDS ROW
                    Row(
                      children: [
                        Expanded(
                          child: _passengerCard(
                            "AP",
                            "Arjun P.",
                            "Drop: Magarpatta",
                            "8 min",
                            Color(0xFFEDE9FE),
                            Color(0xFF5B21B6),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _passengerCard(
                            "PB",
                            "Priya B.",
                            "Drop: Kharadi",
                            "15 min",
                            Color(0xFFFEF3C7),
                            Color(0xFF92400E),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "Earning",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "₹191",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A9E6E),
                                  ),
                                ),
                                Text(
                                  "total",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    /// 💺 SEAT GRID
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2.2,
                      children: [
                        _seatTile("You", Color(0xFF374151), Colors.white),
                        _seatTile(
                          "Arjun",
                          Color(0xFFE6F7F1),
                          Color(0xFF0D6B4A),
                        ),
                        _seatTile(
                          "Priya",
                          Color(0xFFFEF3C7),
                          Color(0xFF92400E),
                        ),
                        _seatTile(
                          "Free",
                          Color(0xFFF3F4F6),
                          Color(0xFF9CA3AF),
                          isDashed: true,
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    /// ✅ COMPLETE RIDE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DriverTripSummaryPage(phone: phone),
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
                          "Complete Ride",
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

  Widget _passengerCard(
    String initials,
    String name,
    String drop,
    String eta,
    Color avatarBg,
    Color avatarFg,
  ) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(drop, style: TextStyle(fontSize: 10, color: Colors.grey)),
          SizedBox(height: 2),
          Text(
            eta,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A9E6E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seatTile(String label, Color bg, Color fg, {bool isDashed = false}) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}
