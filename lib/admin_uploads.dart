import 'package:flutter/material.dart';

class AdminUploadsScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final bool isDarkMode;
  final Function(bool) onToggleTheme;

  const AdminUploadsScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome Admin: $userName'),
            const SizedBox(height: 20),
            const Text('Admin uploads functionality will go here'),
          ],
        ),
      ),
    );
  }
}