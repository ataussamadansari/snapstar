import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'This section contains your app privacy policy. Add your final legal privacy text here.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
      ),
    );
  }
}
