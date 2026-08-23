import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const Assignment02App());
}

class Assignment02App extends StatelessWidget {
  const Assignment02App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
