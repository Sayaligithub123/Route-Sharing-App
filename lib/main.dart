import 'package:flutter/material.dart';
import 'splashscreen.dart'; // import your screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // 👈 CHANGE HERE
    );
  }
}
