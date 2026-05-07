import 'package:flutter/material.dart';
import 'passenger_home.dart';
import 'Driver_homepage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String role;

  const ProfileSetupScreen({super.key, required this.role});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  // 🔹 Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final vehicleNameController = TextEditingController();
  final vehicleNumberController = TextEditingController();
  final licenseController = TextEditingController();

  bool isLoading = false;

  // 🔥 API CALL
  Future<bool> saveProfile() async {
    final url = Uri.parse("http://192.168.31.159:5000/api/users/create");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "role": widget.role,
          "name": nameController.text,
          "email": emailController.text,
          "phone": phoneController.text,

          "vehicleName": widget.role == "Driver"
              ? vehicleNameController.text
              : null,
          "vehicleNumber": widget.role == "Driver"
              ? vehicleNumberController.text
              : null,
          "license": widget.role == "Driver" ? licenseController.text : null,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print("Saved: $data");
        
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', data['_id']);
        await prefs.setString('role', data['role']);
        await prefs.setString('userData', jsonEncode(data));
        
        return true;
      } else {
        print("Error saving profile: ${response.statusCode} - ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${response.body}")),
          );
        }
        return false;
      }
    } catch (e) {
      print("Exception during saveProfile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network error: Check if backend is running.")),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Your Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Profile Photo
            Column(
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: const Icon(Icons.add, size: 30),
                ),
                const SizedBox(height: 10),
                const Text("Upload photo"),
              ],
            ),

            const SizedBox(height: 20),

            // Common Fields
            buildField("FULL NAME", nameController),
            buildField("EMAIL (OPTIONAL)", emailController),
            buildField("PHONE", phoneController),

            const SizedBox(height: 20),

            // Driver Fields
            if (widget.role == "Driver") ...[
              buildField("VEHICLE NAME", vehicleNameController),
              buildField("VEHICLE NUMBER", vehicleNumberController),
              buildField("DRIVING LICENSE", licenseController),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: isLoading ? null : () async {
                setState(() {
                  isLoading = true;
                });
                
                bool success = await saveProfile();

                setState(() {
                  isLoading = false;
                });

                if (success && mounted) {
                  final nextScreen = widget.role == "Driver"
                      ? const DriverHomeScreen()
                      : const PassengerHomeScreen();

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => nextScreen),
                  );
                }
              },
              child: isLoading 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("Complete Setup →"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
