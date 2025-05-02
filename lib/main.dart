import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_page.dart';
import 'login.dart';
import 'settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

/// Wrapper to manage dynamic theme switching
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false; // Controls whether dark mode is enabled.

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  // Load the theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  // Save the theme preference and update the state
  Future<void> _toggleTheme(bool isDark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = isDark;
    });
    await prefs.setBool('darkMode', isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Certificate Auth App',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => WelcomePage(
          isDarkMode: _isDarkMode, // Pass the current theme mode
          onToggleTheme: _toggleTheme, // Pass the toggle function
        ),
        '/login': (context) => LoginPage(
          isDarkMode: _isDarkMode, // Pass the current theme mode
          onToggleTheme: _toggleTheme, // Pass the toggle function
        ),
        '/settings': (context) => SettingsScreen(
          isDarkMode: _isDarkMode, // Pass the current theme mode
          onToggleTheme: _toggleTheme, userName: '', userEmail: '', // Pass the toggle function
        ),
      },
    );
  }
}

/// QR Code Scanner Screen
class QRCodeScannerScreen extends StatefulWidget {
  const QRCodeScannerScreen({super.key});

  @override
  State<QRCodeScannerScreen> createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen> {
  bool hasScanned = false; // Tracks whether a QR code has been scanned.

  // Show a success dialog with the scanned code
  void showSuccessDialog(String scannedCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/success.json', // Ensure this asset exists.
              height: 120,
              repeat: false,
            ),
            const SizedBox(height: 10),
            const Text(
              "Scan Successful!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("Scanned Data:"),
            const SizedBox(height: 5),
            SelectableText(
              scannedCode,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  hasScanned = false; // Reset the scanning state.
                });
              },
              child: const Text("OK"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              onDetect: (BarcodeCapture capture) {
                if (!hasScanned) {
                  final Barcode? barcode = capture.barcodes.first;
                  final String? code = barcode?.rawValue;
                  if (code != null) {
                    setState(() {
                      hasScanned = true; // Mark as scanned to prevent duplicates.
                    });
                    showSuccessDialog(code);
                  }
                }
              },
            ),
          ),
          const Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Scan a QR code',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
