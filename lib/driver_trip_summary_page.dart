import 'package:flutter/material.dart';
import 'Driver_homepage.dart';

class DriverTripSummaryPage extends StatefulWidget {
  final String? phone;
  final dynamic rideData;

  const DriverTripSummaryPage({super.key, this.phone, this.rideData});

  @override
  State<DriverTripSummaryPage> createState() => _DriverTripSummaryPageState();
}

class _DriverTripSummaryPageState extends State<DriverTripSummaryPage> {
  // Store dynamic passenger rating states
  final Map<String, int> _passengerRatings = {};

  // Color palette for passenger avatars
  final List<Map<String, Color>> _colorPalette = [
    {'bg': const Color(0xFFEDE9FE), 'fg': const Color(0xFF5B21B6)},
    {'bg': const Color(0xFFFEF3C7), 'fg': const Color(0xFF92400E)},
    {'bg': const Color(0xFFDCFCE7), 'fg': const Color(0xFF166534)},
    {'bg': const Color(0xFFDBEAFE), 'fg': const Color(0xFF1E40AF)},
  ];

  @override
  Widget build(BuildContext context) {
    // 1. Parse rideData or use robust fallback values
    String source = 'Station';
    String destination = 'Hadapsar';
    int driverEarnings = 191;
    int totalFaresCollected = 212;
    int platformCommission = 21;
    double tripDistance = 8.4;
    int tripDuration = 28;
    
    List<dynamic> passengers = [];

    if (widget.rideData != null) {
      final ride = widget.rideData;
      source = ride['source'] ?? 'Source';
      destination = ride['destination'] ?? 'Destination';
      
      driverEarnings = (ride['driverEarnings'] as num?)?.toInt() ?? 191;
      totalFaresCollected = (ride['totalFaresCollected'] as num?)?.toInt() ?? 212;
      platformCommission = (ride['platformCommission'] as num?)?.toInt() ?? 21;
      
      if (ride['passengers'] is List) {
        passengers = ride['passengers'] as List;
      }

      // Compute total distance based on passengers or default
      double maxDist = 0.0;
      for (var p in passengers) {
        final d = (p['distance'] as num?)?.toDouble() ?? 0.0;
        if (d > maxDist) maxDist = d;
      }
      tripDistance = maxDist > 0 ? maxDist : 8.4;
      tripDuration = maxDist > 0 ? (maxDist * 2.5).round() : 28;
    } else {
      // Setup demo fallback passengers list
      passengers = [
        {
          '_id': '1',
          'name': 'Arjun Mehta',
          'sharedFare': 143,
          'soloFare': 200,
          'savings': 57,
          'distance': 8.4,
          'dropLocation': 'Hadapsar'
        },
        {
          '_id': '2',
          'name': 'Priya Bose',
          'sharedFare': 48,
          'soloFare': 70,
          'savings': 22,
          'distance': 3.2,
          'dropLocation': 'Station Detour'
        }
      ];
    }

    // Initialize passenger ratings map if empty
    for (var p in passengers) {
      final id = p['_id']?.toString() ?? p['name'] ?? '';
      if (!_passengerRatings.containsKey(id)) {
        _passengerRatings[id] = 5; // Default 5 star rating
      }
    }

    // Dynamic Route Sharing Bonus:
    // Solo earnings would be 90% of the first passenger's solo fare (driver baseline)
    int baselineSoloFare = passengers.isNotEmpty ? ((passengers[0]['soloFare'] as num?)?.toInt() ?? 130) : 130;
    int soloEarningsIfSingleDriverShare = (baselineSoloFare * 0.90).round();
    int sharedBonus = driverEarnings - soloEarningsIfSingleDriverShare;
    if (sharedBonus < 0) sharedBonus = 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            /// TOP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
                        (route) => false,
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF334155)),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      "Trip Summary",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// 🎉 Celebration Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: const Text("💰", style: TextStyle(fontSize: 36)),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Trip Completed Successfully!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Thank you for boosting route efficiency",
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// 🟢 PREMIUM TOTAL EARNINGS CARD
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "TOTAL NET EARNINGS (90%)",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white70,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "₹$driverEarnings",
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Horizontal separator
                          Container(height: 1, color: Colors.white.withOpacity(0.15)),
                          
                          // Passenger contributions list
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  "PASSENGER CONTRIBUTIONS",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white70,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: passengers.map((p) {
                                    final pName = p['name'] ?? 'Passenger';
                                    final pSharedFare = p['sharedFare'] ?? 0;
                                    return _earnerBox(
                                      "₹$pSharedFare", 
                                      "from ${pName.split(' ').first}",
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// 📊 TRIP METADATA DETAILS CARD
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          _fareRow("Route", "$source → $destination"),
                          _fareRow("Distance", "${tripDistance.toStringAsFixed(1)} km"),
                          _fareRow("Duration", "$tripDuration min"),
                          _fareRow("Passengers Aboard", "${passengers.length} (shared)"),
                          
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Color(0xFFF1F5F9), thickness: 1),
                          ),
                          
                          _fareRowStrikethrough(
                            "Base Solo Driver Earnings",
                            "₹$soloEarningsIfSingleDriverShare",
                          ),
                          _fareRowGreen(
                            "Route-Share Bonus (Extra Earning)",
                            "+₹$sharedBonus",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// ⭐ RATE PASSENGERS SECTION
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Rate your passengers",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey[700],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Passenger rating cards
                    Column(
                      children: passengers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final p = entry.value;
                        final name = p['name'] ?? 'Passenger';
                        final pId = p['_id']?.toString() ?? name;
                        final colors = _colorPalette[index % _colorPalette.length];
                        final initials = _getInitials(name);
                        final currentRating = _passengerRatings[pId] ?? 5;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: colors['bg'],
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: colors['fg'],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Ratings stars
                                    Row(
                                      children: List.generate(5, (starIdx) {
                                        final starValue = starIdx + 1;
                                        final isFilled = starValue <= currentRating;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _passengerRatings[pId] = starValue;
                                            });
                                          },
                                          child: Icon(
                                            isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                                            size: 26,
                                            color: isFilled ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                                          ),
                                        );
                                      }),
                                    )
                                  ],
                                ),
                              ),
                              Text(
                                currentRating == 5 ? "Excellent!" : "$currentRating Star",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                ),
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 28),

                    /// 🚀 DONE BUTTON
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DriverHomeScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          "Done → Back Home",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label, 
          style: const TextStyle(
            fontSize: 11, 
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          )
        ),
      ],
    );
  }

  Widget _fareRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareRowStrikethrough(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareRowGreen(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : "?";
  }
}
