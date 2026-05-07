import 'package:flutter/material.dart';
import 'Avaible_rides.dart';

class PlanRideScreen extends StatefulWidget {
  const PlanRideScreen({super.key});

  @override
  State<PlanRideScreen> createState() => _PlanRideScreenState();
}

class _PlanRideScreenState extends State<PlanRideScreen> {
  String pickup = "";
  String destination = "";

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
                          onChanged: (value) => pickup = value,
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
                          onChanged: (value) => destination = value,
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

            // ❌ No dummy data → Empty state
            const Expanded(
              child: Center(
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
