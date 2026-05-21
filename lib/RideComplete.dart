import 'package:flutter/material.dart';
import 'package:share_route_app/passenger_home.dart';

class RideCompleteScreen extends StatelessWidget {
  final dynamic rideData;

  const RideCompleteScreen({super.key, this.rideData});

  @override
  Widget build(BuildContext context) {
    String source = '--';
    String destination = '--';
    String driverName = '--';

    if (rideData != null) {
      source = rideData['source'] ?? '--';
      destination = rideData['destination'] ?? '--';
      if (rideData['driverId'] is Map) {
        driverName = rideData['driverId']['name'] ?? '--';
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [

              const SizedBox(height: 20),

              // 🎉 Title
              const Column(
                children: [
                  Icon(Icons.celebration, size: 50, color: Colors.orange),
                  SizedBox(height: 10),
                  Text(
                    "Ride Complete!",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Thanks for riding with us",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 💰 Amount Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text("Amount paid"),
                        SizedBox(height: 5),
                        Text("₹--",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        Text("You saved"),
                        SizedBox(height: 5),
                        Text("₹--",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 📊 Ride Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Route: $source → $destination"),
                    const SizedBox(height: 8),
                    Text("Driver: $driverName"),
                    const SizedBox(height: 8),
                    const Text("Duration: --"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ⭐ Rating
              const Text(
                "Rate your driver",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => const Icon(Icons.star_border, size: 30),
                ),
              ),

              const SizedBox(height: 20),

              // 💬 Comment Box
              TextField(
                decoration: InputDecoration(
                  hintText: "Leave a comment (optional)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                  onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PassengerHomeScreen(),
                          ),
                        );
                      },
                child: const Text("Submit & Done"),
              ),

              const SizedBox(height: 10),
             
            ],
          ),
        ),
      ),
    );
  }
}
