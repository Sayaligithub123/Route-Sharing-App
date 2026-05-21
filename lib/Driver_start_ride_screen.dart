import 'package:flutter/material.dart';
import 'Driver_Active_Ride.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_config.dart';

class StartRideScreen extends StatefulWidget {
  const StartRideScreen({super.key});

  @override
  State<StartRideScreen> createState() => _StartRideScreenState();
}

class _StartRideScreenState extends State<StartRideScreen> {
  int selectedSeats = 2;
  String source = "";
  String destination = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Where are you going?")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Source Input
            TextField(
              decoration: const InputDecoration(
                hintText: "Enter pickup location (source)",
              ),
              onChanged: (value) {
                source = value;
              },
            ),
            const SizedBox(height: 20),

            // Destination Input
            TextField(
              decoration: const InputDecoration(hintText: "Enter destination"),
              onChanged: (value) {
                destination = value;
              },
            ),

            const SizedBox(height: 20),

            // Seats selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [1, 2, 3].map((seat) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedSeats = seat;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedSeats == seat
                            ? Colors.green
                            : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text("$seat"),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            // Go Live Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () async {
                if (source.isEmpty || destination.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter both source and destination"),
                    ),
                  );
                  return;
                }

                final prefs = await SharedPreferences.getInstance();
                final driverId = prefs.getString('userId');
                if (driverId == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Error: Driver ID not found"),
                      ),
                    );
                  }
                  return;
                }

                final url = Uri.parse(
                  "${ApiConfig.baseUrl}/api/rides/start",
                );
                try {
                  final response = await http.post(
                    url,
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({
                      "driverId": driverId,
                      "source": source,
                      "destination": destination,
                      "availableSeats": selectedSeats,
                    }),
                  );
                  if (response.statusCode == 201 ||
                      response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    final rideId = data['ride']['_id'];
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActiveRideScreen(
                            rideId: rideId,
                            source: source,
                            destination: destination,
                          ),
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: ${response.body}")),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Network error: $e")),
                    );
                  }
                }
              },
              child: const Text("Go Live — Start Ride →"),
            ),
          ],
        ),
      ),
    );
  }
}
