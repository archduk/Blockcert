import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cert_auth.dart';
import 'settings.dart';
import 'help.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final bool isDarkMode;
  final Function(bool) onToggleTheme;
  final String userEmail;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.userEmail,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  // Verification statistics
  int totalCertificates = 0;
  int totalTranscripts = 0;
  int successfulVerifications = 0;
  int failedVerifications = 0;

  // Recent verifications list
  List<Map<String, dynamic>> recentVerifications = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('http://IP ADDRESS/block_cert/verification.php'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          totalCertificates = data['total_certificates_verified'] ?? 0;
          totalTranscripts = data['total_transcripts_verified'] ?? 0;
          successfulVerifications = data['successful_authentications'] ?? 0;
          failedVerifications = data['failed_verifications'] ?? 0;
          recentVerifications = List<Map<String,
              dynamic>>.from(
              data['recent_verifications']
                  ?.map((v) => Map<String, dynamic>.from(v)) ?? []);
        });
      } else {
        if (mounted) {
          // Check if the widget is still in the tree
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are now logged in')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Check if the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        // Check if the widget is still in the tree
        setState(() => _isLoading = false);
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) =>
              HelpScreen(isDarkMode: false, onToggleTheme: (bool p1) {},)));
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SettingsScreen(
                isDarkMode: widget.isDarkMode,
                onToggleTheme: widget.onToggleTheme,
                userName: widget.userName,
                // Pass the userName
                userEmail: widget.userEmail, // Pass the userEmail
              ),
        ),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color,
      {bool isCard = false}) {
    return Card(
      elevation: isCard ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
        // Use withOpacity
      ),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationHistory() {
    if (recentVerifications.isEmpty) {
      return Center(
        child: Text(
          "No verification history yet",
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentVerifications.length,
      itemBuilder: (context, index) {
        final verification = recentVerifications[index];
        final isSuccess = verification['status'] == 'Success';
        final type = verification['type'] ?? 'Document';
        final date = verification['date'] ?? '';
        final message = verification['message'] ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSuccess ? Colors.green[50] : Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check : Icons.close,
                color: isSuccess ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              "$type Verification",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date),
                if (message.isNotEmpty)
                  Text(
                    message,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
            trailing: Chip(
              label: Text(
                verification['status'] ?? '',
                style: TextStyle(
                  color: isSuccess ? Colors.green : Colors.red,
                ),
              ),
              backgroundColor: isSuccess ? Colors.green[50] : Colors.red[50],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startNewVerification() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CertificateAuthenticationScreen(
              isDarkMode: widget.isDarkMode,
            ),
      ),
    );

    if (result != null && result is Map) {
      _handleVerificationResult(Map<String, dynamic>.from(result));
    }
  }

  void _handleVerificationResult(Map<String, dynamic> result) {
    final type = result['type'] ?? 'Document';
    final isSuccess = result['isSuccess'] ?? false;

    setState(() {
      if (type == 'Certificate') {
        totalCertificates++;
      } else if (type == 'Transcript') {
        totalTranscripts++;
      }

      if (isSuccess) {
        successfulVerifications++;
      } else {
        failedVerifications++;
      }

      recentVerifications.insert(0, {
        'type': type,
        'status': isSuccess ? 'Success' : 'Failed',
        'date': result['timestamp'],
        'message': result['message'],
      });

      if (recentVerifications.length > 10) {
        recentVerifications = recentVerifications.sublist(0, 10);
      }
    });
    _showResultSnackbar(isSuccess, type);
  }

  void _showResultSnackbar(bool isSuccess, String type) {
    if (mounted) {
      // Check if the widget is still in the tree
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSuccess
                ? '✅ $type verified successfully'
                : '❌ $type verification failed',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard',
            style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery
                .of(context)
                .size
                .height -
                kToolbarHeight -
                kBottomNavigationBarHeight -
                32, // padding
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${widget.userName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Statistics Cards
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  _buildStatCard(
                    "Certificates",
                    totalCertificates.toString(),
                    Icons.description,
                    Colors.blue,
                    isCard: true,
                  ),
                  _buildStatCard(
                    "Transcripts",
                    totalTranscripts.toString(),
                    Icons.description,
                    Colors.blue,
                    isCard: true,
                  ),
                  _buildStatCard(
                    "Successful",
                    successfulVerifications.toString(),
                    Icons.check_circle,
                    Colors.green,
                    isCard: true,
                  ),
                  _buildStatCard(
                    "Failed",
                    failedVerifications.toString(),
                    Icons.warning,
                    Colors.red,
                    isCard: true,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Recent Verifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildVerificationHistory(),

              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.verified_user),
                  label: const Text('New Verification'),
                  onPressed: _startNewVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16), // Extra space to prevent overflow
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
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
      ),
    );
  }
}

