import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile.dart';
import 'dashboard.dart';
import 'help.dart';
import 'dart:math';
import 'dart:async';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onToggleTheme;
  final String userName;
  final String userEmail;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 2;
  bool is2FAEnabled = false;
  String selectedLanguage = 'English';
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  late bool _isDarkMode;

  String? _generatedToken;
  DateTime? _tokenExpiry;
  Timer? _tokenTimer;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _loadPreferences();
  }

  @override
  void dispose() {
    _tokenTimer?.cancel();
    _phoneController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      is2FAEnabled = prefs.getBool('2FA') ?? false;
      selectedLanguage = prefs.getString('language') ?? 'English';
      _isDarkMode = prefs.getBool('darkMode') ?? widget.isDarkMode;
    });
  }

  Future<void> _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('2FA', is2FAEnabled);
    await prefs.setString('language', selectedLanguage);
    await prefs.setBool('darkMode', _isDarkMode);
  }

  String _generateToken() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  void _startTokenTimer() {
    _tokenTimer?.cancel();
    _tokenTimer = Timer(const Duration(minutes: 5), () {
      setState(() {
        _generatedToken = null;
        _tokenExpiry = null;
      });
    });
  }

  void _send2FAToken() {
    _phoneController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Verify Phone Number"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Enter Phone Number",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_phoneController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a phone number")),
                    );
                    return;
                  }

                  final token = _generateToken();
                  setState(() {
                    _generatedToken = token;
                    _tokenExpiry = DateTime.now().add(const Duration(minutes: 5));
                  });
                  _startTokenTimer();

                  Navigator.pop(context);
                  _showTokenVerificationDialog();
                },
                child: const Text("Send Token"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTokenVerificationDialog() {
    _tokenController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Enter Verification Token"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Token sent to ${_phoneController.text}"),
              const SizedBox(height: 16),
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: "6-digit Token",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 8),
              Text(
                _tokenExpiry != null
                    ? "Expires in ${_tokenExpiry!.difference(DateTime.now()).inMinutes} minutes"
                    : "Token expired",
                style: TextStyle(
                  color: _tokenExpiry != null ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_tokenController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter the token")),
                  );
                  return;
                }

                if (_tokenController.text != _generatedToken) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid token")),
                  );
                  return;
                }

                if (_tokenExpiry == null || DateTime.now().isAfter(_tokenExpiry!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Token has expired")),
                  );
                  return;
                }

                setState(() {
                  is2FAEnabled = true;
                  _generatedToken = null;
                  _tokenExpiry = null;
                });
                _savePreferences();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Two-factor authentication enabled")),
                );
              },
              child: const Text("Verify"),
            ),
          ],
        );
      },
    );
  }

  void _changeLanguage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Select Language"),
          content: DropdownButton<String>(
            value: selectedLanguage,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedLanguage = newValue;
                });
                _savePreferences();
                Navigator.pop(context);
              }
            },
            items: <String>['English', 'Spanish', 'French']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isDarkMode
                  ? [Colors.grey[900]!, Colors.grey[800]!] // Darker shade for dark mode
                  : [Colors.blue, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Account Settings",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black, // Text color based on mode
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  isDarkMode: _isDarkMode,
                ),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(12),
                color: _isDarkMode
                    ? Colors.grey[800] // Dark container for dark mode
                    : Colors.white, // Light container for light mode
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Profile",
                    style: TextStyle(
                      fontSize: 16,
                      color: _isDarkMode ? Colors.white : Colors.black, // Text color
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Security Preferences",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black, // Text color
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
              color: _isDarkMode
                  ? Colors.grey[800] // Dark container for dark mode
                  : Colors.white, // Light container for light mode
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Two-Factor Authentication",
                  style: TextStyle(
                    fontSize: 16,
                    color: _isDarkMode ? Colors.white : Colors.black, // Text color
                  ),
                ),
                Switch(
                  value: is2FAEnabled,
                  onChanged: (val) {
                    if (val) {
                      _send2FAToken();
                    } else {
                      setState(() {
                        is2FAEnabled = val;
                      });
                      _savePreferences();
                    }
                  },
                  activeColor: Colors.blue, // Consistent active color
                  inactiveTrackColor: _isDarkMode
                      ? Colors.grey[700]!
                      : Colors.grey[300], //Proper colors for track
                  inactiveThumbColor:
                  _isDarkMode ? Colors.grey[200] : Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "App Configurations",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black, // Text color
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
              color: _isDarkMode
                  ? Colors.grey[800] // Dark container for dark mode
                  : Colors.white, // Light container for light mode
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Dark Mode",
                      style: TextStyle(
                        fontSize: 16,
                        color: _isDarkMode ? Colors.white : Colors.black, // Text color
                      ),
                    ),
                    Switch(
                      value: _isDarkMode,
                      onChanged: (val) async {
                        setState(() {
                          _isDarkMode = val;
                        });
                        widget.onToggleTheme(val);
                        await _savePreferences();
                      },
                      activeColor: Colors.blue, // Consistent active color.
                      inactiveTrackColor: _isDarkMode
                          ? Colors.grey[700]!
                          : Colors.grey[300], // Proper colors for track
                      inactiveThumbColor:
                      _isDarkMode ? Colors.grey[200] : Colors.white,
                    ),
                  ],
                ),
                Divider(
                  color: _isDarkMode ? Colors.grey[600] : Colors.grey[300],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Language: $selectedLanguage",
                      style: TextStyle(
                        fontSize: 16,
                        color: _isDarkMode ? Colors.white : Colors.black, // Text color
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _changeLanguage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        Colors.blue, // Keep button color as blue, doesn't change with dark mode in this design
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Change"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(
                  userName: widget.userName,
                  isDarkMode: _isDarkMode,
                  onToggleTheme: widget.onToggleTheme,
                  userEmail: widget.userEmail,
                ),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HelpScreen(
                  isDarkMode: _isDarkMode,
                  onToggleTheme: widget.onToggleTheme,
                ),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(
                  userName: widget.userName,
                  isDarkMode: _isDarkMode,
                  onToggleTheme: widget.onToggleTheme,
                  userEmail: widget.userEmail,
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
        unselectedItemColor: _isDarkMode ? Colors.grey[400] : Colors.grey,
        backgroundColor:
        _isDarkMode ? Colors.grey[800] : Colors.white, // set background color
      ),
      backgroundColor:
      _isDarkMode ? Colors.grey[900] : Colors.grey[100], // Set overall background.
    );
  }
}

