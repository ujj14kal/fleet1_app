import 'package:flutter/material.dart';

void main() {
  runApp(Fleet1App());
}

class Fleet1App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fleet1',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Fleet1"),
      ),
      body: Center(
        child: Text(
          "Welcome to Fleet1 🚖",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}