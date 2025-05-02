import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dashboard.dart';
import 'settings.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key, required this.isDarkMode, required this.onToggleTheme}) : super(key: key);

  final bool isDarkMode;
  final Function(bool) onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildFAQItem(
              question: 'How do I verify a certificate?',
              answer:
              'Tap on "Start Verification" button and follow the on-screen instructions to scan or upload your document.',
            ),
            _buildFAQItem(
              question: 'What document formats are supported?',
              answer:
              'We support PDF, PNG, and JPG formats for certificate verification.',
            ),
            _buildFAQItem(
              question: 'Why did my verification fail?',
              answer:
              'Verification may fail if the document is damaged, altered, or not issued by a recognized institution.',
            ),
            const SizedBox(height: 30),
            const Text(
              'Contact Support',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildContactOption(
              icon: Icons.email,
              title: 'Email Us',
              subtitle: 'support@certverify.com',
              onTap: _launchEmail,
            ),
            _buildContactOption(
              icon: Icons.phone,
              title: 'Call Support',
              subtitle: '+254 746736229',
              onTap: () => _launchPhone('+254746736229'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(
                  userName: "",
                  isDarkMode: isDarkMode,
                  onToggleTheme: onToggleTheme,
                  userEmail: "",
                ),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(
                  userName: "",
                  isDarkMode: isDarkMode,
                  onToggleTheme: onToggleTheme,
                  userEmail: "",
                ),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Help',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(fontSize: 16),
          ),
          const Divider(height: 30),
        ],
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  static Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'blockcertverify@gmail.com',
    );
    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      throw 'Could not launch email!';
    }
  }

  static Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      throw 'Could not launch phone call!';
    }
  }
}

