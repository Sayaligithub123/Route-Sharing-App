import 'package:flutter/material.dart';

class DriverProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const DriverProfileScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Driver Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),

            const SizedBox(height: 10),

            Text(
              userData['name'] ?? "",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // Common
            buildTile("Email", userData['email']),
            buildTile("Phone", userData['phone']),

            const SizedBox(height: 10),

            // Driver specific
            buildTile("Vehicle Name", userData['vehicleName']),
            buildTile("Vehicle Number", userData['vehicleNumber']),
            buildTile("License", userData['license']),
          ],
        ),
      ),
    );
  }

  Widget buildTile(String title, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(title), Text(value ?? "--")],
      ),
    );
  }
}
