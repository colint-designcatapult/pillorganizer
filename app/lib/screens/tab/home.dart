import 'package:flutter/material.dart'; // ensure you import 'material.dart'

class HomePage extends StatelessWidget {
  const HomePage({Key? key})
      : super(key: key); // Fixed the super key constructor

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xF1F6F5FF),
      child: const Center(child: Text('Home Page')),
    );
  }
}
