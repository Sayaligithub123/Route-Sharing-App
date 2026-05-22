import 'package:flutter/material.dart';
import 'Avaible_rides.dart';
import 'services/route_service.dart';

class PlanRideScreen extends StatefulWidget {
  const PlanRideScreen({super.key});

  @override
  State<PlanRideScreen> createState() => _PlanRideScreenState();
}

class _PlanRideScreenState extends State<PlanRideScreen> {
  String pickup = "";
  String destination = "";

  String routeDistance = "";
  String routeDuration = "";
  bool isCalculating = false;
  int? soloFare;
  int? sharedFare;

  Future<void> _updateEstimate() async {
    if (pickup.isEmpty || destination.isEmpty) return;
    setState(() {
      isCalculating = true;
    });
    try {
      final info = await RouteService.calculateRoute(pickup, destination);
      if (mounted) {
        setState(() {
          if (info != null) {
            double dist = info['distance'] ?? 0.0;
            double dur = info['duration'] ?? 0.0;
            routeDistance = "${dist.toStringAsFixed(1)} km";
            routeDuration = "${dur.toStringAsFixed(0)} mins";
            soloFare = (40 + 12 * dist).round();
            sharedFare = (soloFare! * 0.70).round(); // 30% savings estimate
          } else {
            routeDistance = "";
            routeDuration = "";
            soloFare = null;
            sharedFare = null;
          }
          isCalculating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCalculating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Plan your ride"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Source & Destination Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Pickup
                  Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.green, size: 10),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            pickup = value;
                            _updateEstimate();
                          },
                          decoration: InputDecoration(
                            hintText: "Enter pickup location",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Destination
                  Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.red, size: 10),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            destination = value;
                            _updateEstimate();
                          },
                          decoration: InputDecoration(
                            hintText: "Enter destination",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 Suggestions Title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "SUGGESTIONS",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Dynamic Fare Estimate Card or Suggestions
            Expanded(
              child: isCalculating
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  : (soloFare != null)
                      ? Center(
                          child: SingleChildScrollView(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.route, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Text(
                                        "$routeDistance ($routeDuration)",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            const Text(
                                              "Solo Ride",
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "₹$soloFare",
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: Colors.grey[200],
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  "Co-Ride Share",
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green[50],
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    "-30%",
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "₹$sharedFare",
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "🎉 Save ₹${soloFare! - sharedFare!} instantly ",
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const Text(
                                          "by sharing with co-riders!",
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const Center(
                          child: Text(
                            "No suggestions yet",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
            ),

            // 🔹 Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  if (pickup.isEmpty || destination.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter pickup and destination")));
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RidesScreen(source: pickup, destination: destination),
                    ),
                  );
                },
                child: const Text("Find Rides on This Route →"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
