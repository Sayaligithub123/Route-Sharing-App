import 'package:flutter/material.dart';
import 'passenger_home.dart';
import 'Driver_homepage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_config.dart';

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

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // 🔥 API CALL
  Future<bool> saveProfile() async {
    // Validate form fields first
    if (!(_formKey.currentState?.validate() ?? false)) {
      // Show a snackbar indicating validation failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the highlighted errors.')),
      );
      return false;
    }

    final url = Uri.parse("${ApiConfig.baseUrl}/api/users/create");

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
        print(
          "Error saving profile: ${response.statusCode} - ${response.body}",
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
        }
        return false;
      }
    } catch (e) {
      print("Exception during saveProfile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Network error: Check if backend is running."),
          ),
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
        child: Form(
          key: _formKey,
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
              buildFormField("FULL NAME", nameController, (value) {
                if (value == null || value.isEmpty) return 'Name is required';
                return null;
              }),
              buildFormField("EMAIL (OPTIONAL)", emailController, (value) {
                if (value != null && value.isNotEmpty) {
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}');
                  if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
                }
                return null;
              }),
              buildFormField("PHONE", phoneController, (value) {
                if (value == null || value.isEmpty)
                  return 'Phone number is required';
                final numeric = RegExp(r'^\d{10,15}');
                if (!numeric.hasMatch(value))
                  return 'Enter a valid phone number';
                return null;
              }),
              const SizedBox(height: 20),
              // Driver Fields
              if (widget.role == "Driver") ...[
                buildFormField(
                  "VEHICLE NAME",
                  vehicleNameController,
                  (value) => null,
                ),
                buildFormField(
                  "VEHICLE NUMBER",
                  vehicleNumberController,
                  (value) => null,
                ),
                buildFormField(
                  "DRIVING LICENSE",
                  licenseController,
                  (value) => null,
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
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
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Complete Setup →"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFormField(
    String label,
    TextEditingController controller,
    String? Function(String?) validator,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
