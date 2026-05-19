import 'package:flutter/material.dart';

class DriverProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DriverProfileScreen({super.key, required this.userData});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _vehicleNameController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userData['name'] ?? '';
    _emailController.text = widget.userData['email'] ?? '';
    _phoneController.text = widget.userData['phone'] ?? '';
    _vehicleNameController.text = widget.userData['vehicleName'] ?? '';
    _vehicleNumberController.text = widget.userData['vehicleNumber'] ?? '';
    _licenseController.text = widget.userData['license'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vehicleNameController.dispose();
    _vehicleNumberController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\d{10,15}\$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validateNotEmpty(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '\$field is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Driver Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: _validateName,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: _validatePhone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _vehicleNameController,
                decoration: const InputDecoration(labelText: 'Vehicle Name'),
                validator: (v) => _validateNotEmpty(v, 'Vehicle Name'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _vehicleNumberController,
                decoration: const InputDecoration(labelText: 'Vehicle Number'),
                validator: (v) => _validateNotEmpty(v, 'Vehicle Number'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(labelText: 'License'),
                validator: (v) => _validateNotEmpty(v, 'License'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
